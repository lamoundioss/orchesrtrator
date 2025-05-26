import json
import logging
import time
from threading import Lock, Thread

import pika
from pika.exceptions import AMQPConnectionError, StreamLostError

from .config import Config
from .models import Order

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class RabbitMQConsumer:
    def __init__(self, app):
        self.app = app  # Stocker l'application Flask
        self._connection = None
        self._channel = None
        self._lock = Lock()
        self._reconnect_delay = 5
        self._should_reconnect = True
        self._started = False
        self.connect()

    def connect(self):
        try:
            credentials = pika.PlainCredentials(Config.RABBITMQ_USER, Config.RABBITMQ_PASSWORD)
            parameters = pika.ConnectionParameters(Config.RABBITMQ_HOST, 5672, '/', credentials)
            self._connection = pika.BlockingConnection(parameters)
            
            self._channel = self._connection.channel()
            self._channel.queue_declare(queue=Config.RABBITMQ_TASK_QUEUE, durable=True)
            self._channel.queue_declare(
                queue=Config.RABBITMQ_RESPONSE_QUEUE, durable=True
            )
            logger.info("Connected to RabbitMQ")
        except Exception as e:
            logger.error(f"Failed to connect to RabbitMQ: {str(e)}")
            self.reconnect()

    def reconnect(self):
        if self._should_reconnect:
            logger.info(f"Reconnecting in {self._reconnect_delay} seconds...")
            time.sleep(self._reconnect_delay)
            self.connect()

    def start_consuming(self):
        def _consume():
            while self._should_reconnect:
                try:
                    if not self._connection or self._connection.is_closed:
                        self.reconnect()

                    self._channel.basic_consume(
                        queue=Config.RABBITMQ_TASK_QUEUE,
                        on_message_callback=self._process_message,
                        auto_ack=False,
                    )

                    logger.info("Starting message consumption...")
                    self._channel.start_consuming()
                except (AMQPConnectionError, StreamLostError) as e:
                    logger.error(f"Connection lost: {str(e)}")
                    self.reconnect()
                except Exception as e:
                    logger.error(f"Unexpected error: {str(e)}")
                    time.sleep(1)

        if not self._started:
            Thread(target=_consume, daemon=True).start()
            self._started = True

    def _process_message(self, ch, method, properties, body):
        # Utiliser le contexte de l'application Flask
        with self.app.app_context():
            try:
                message = json.loads(body)
                action = message.get("action")
                data = message.get("data")

                logger.info(f"Processing action: {action}")

                if action == "create_order":
                    order = Order.create(
                        data["user_id"], data["number_of_items"], data["total_amount"]
                    )
                    response = {
                        "status": "success",
                        "message": "Facture créée avec succès.",
                        "data": order.to_dict(),
                    }

                    logger.info(f"CREATING ORDER ...{response}")

                else:
                    response = {
                        "status": "error",
                        "message": f"Action non reconnue: {action}",
                    }

                # Envoyer la réponse
                if properties.reply_to:
                    ch.basic_publish(
                        exchange="",
                        routing_key=properties.reply_to,
                        properties=pika.BasicProperties(
                            correlation_id=properties.correlation_id
                        ),
                        body=json.dumps(response),
                    )

                ch.basic_ack(delivery_tag=method.delivery_tag)

            except json.JSONDecodeError:
                logger.error("Invalid JSON message")
                ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
            except Exception as e:
                logger.error(f"Processing error: {str(e)}")
                ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)

    def close(self):
        self._should_reconnect = False
        if self._connection and self._connection.is_open:
            self._connection.close()
            logger.info("RabbitMQ connection closed")


# Initialisation globale
consumer = None


def register_routes(app):
    global consumer

    # Initialisation du consommateur RabbitMQ
    consumer = RabbitMQConsumer(app)
    consumer.start_consuming()

    # Nettoyage à la fermeture
    # @app.teardown_appcontext
    # def shutdown_rabbitmq(exception=None):
    #     if consumer:
    #         consumer.close()
