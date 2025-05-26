import json
import logging
import os
import time
import uuid
from threading import Lock

import pika
import requests
from flask import Blueprint, jsonify, request

from .config import Config

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Création des Blueprints
inventory_bp = Blueprint("inventory", __name__, url_prefix="/api/movies")
order_bp = Blueprint("order", __name__, url_prefix="/api/billing")


class RabbitMQClient:
    def __init__(self):
        self._connection = None
        self._channel = None
        self._lock = Lock()
        self._reconnect_delay = 5
        self._should_reconnect = True
        self.connect()

    def close(self):
        if self._connection:
            self._connection.close()

    def connect(self):
        with self._lock:
            try:
                credentials = pika.PlainCredentials(Config.RABBITMQ_USER, Config.RABBITMQ_PASSWORD)
                parameters = pika.ConnectionParameters(Config.RABBITMQ_HOST, 5672, '/', credentials)
                self._connection = pika.BlockingConnection(parameters)
                
                self._channel = self._connection.channel()
                self._channel.queue_declare(
                    queue=Config.RABBITMQ_TASK_QUEUE, durable=True
                )
                logger.info("Successfully connected to RabbitMQ")
                return True
            except Exception as e:
                logger.error(f"Connection failed: {str(e)}")
                self.reconnect()

    def reconnect(self):
        if self._should_reconnect:
            logger.info(f"Reconnecting in {self._reconnect_delay} seconds...")
            time.sleep(self._reconnect_delay)
            self.connect()

    def publish_message(self, action, data):
        for attempt in range(3):
            try:
                with self._lock:
                    if not self._connection or self._connection.is_closed:
                        self.reconnect()

                    correlation_id = str(uuid.uuid4())
                    self._channel.basic_publish(
                        exchange="",
                        routing_key=Config.RABBITMQ_TASK_QUEUE,
                        properties=pika.BasicProperties(
                            reply_to=Config.RABBITMQ_RESPONSE_QUEUE,
                            correlation_id=correlation_id,
                            delivery_mode=2,
                        ),
                        body=json.dumps({"action": action, "data": data}),
                    )
                    print(f"Message published with correlation_id: {correlation_id}")
                    return correlation_id
            except Exception as e:
                logger.error(f"Publish attempt {attempt + 1} failed: {str(e)}")
                self.reconnect()
                time.sleep(1)
        return None


# Initialisation
rabbitmq_client = RabbitMQClient()


@order_bp.route("/", methods=["POST"])
def create_order():
    """Créer une commande."""
    try:
        data = request.get_json()
        print(f"Received data: {data}")
        correlation_id = rabbitmq_client.publish_message(
            action="create_order",
            data={
                "user_id": data["user_id"],
                "number_of_items": data["number_of_items"],
                "total_amount": data["total_amount"],
            },
        )
        if not correlation_id:
            print("Failed to publish message to RabbitMQ")
            raise Exception("Failed to publish message to RabbitMQ")

        return jsonify(
            {"message": "Requête acceptée", "correlation_id": correlation_id}
        ), 200

    except KeyError as e:
        print(f"Missing field: {str(e)}")
        return jsonify({"error": f"Champ manquant: {str(e)}"}), 400
    except Exception as e:
        print(f"Error: {str(e)}")
        return jsonify({"error": str(e)}), 500


@inventory_bp.route("", methods=["GET", "POST", "PUT", "DELETE"])
@inventory_bp.route("/<id>", methods=["GET", "POST", "PUT", "DELETE"])
def route_to_inventory(id=None):
    base_url = Config.INVENTORY_SERVICE_URL
    url = f"{base_url}/{id}" if id else f"{base_url}"
    if request.query_string:
        url += f"?{request.query_string.decode('utf-8')}"

    try:
        response = requests.request(
            method=request.method,
            url=url,
            headers={key: value for key, value in request.headers if key != "Host"},
            json=request.get_json() if request.is_json else None,
            params=request.args,
        )
        return response.content, response.status_code, response.headers.items()
    except requests.exceptions.HTTPError as errh:
        logger.error(f"HTTP Error: {str(errh)}")
        return jsonify({"error": "HTTP Error"}), 500
    except requests.exceptions.ReadTimeout as errrt:
        logger.error(f"Read Timeout: {str(errrt)}")
        return jsonify({"error": "Read Timeout"}), 504
    except requests.exceptions.ConnectionError as conerr:
        logger.error(f"Connection Error: {str(conerr)}")
        return jsonify({"error": "Connection Error"}), 502
    except requests.exceptions.RequestException as errex:
        logger.error(f"Request Exception: {str(errex)}")
        return jsonify({"error": "Request Exception"}), 500


@inventory_bp.route("/health", methods=["GET"])
def healthcheck():
    """Health check endpoint."""
    return jsonify({"status": "ok"}), 200


def register_routes(app):
    app.register_blueprint(inventory_bp)
    app.register_blueprint(order_bp)
