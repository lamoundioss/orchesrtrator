import json
import logging
import time
from threading import Lock, Thread
import ssl

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

    def _create_ssl_context(self):
        """Créer un contexte SSL sécurisé."""
        ssl_context = ssl.create_default_context()
        
        if Config.DEBUG:
            # Développement : SSL relâché
            ssl_context.check_hostname = False
            ssl_context.verify_mode = ssl.CERT_NONE
            logger.warning("Using relaxed SSL verification in development mode")
        else:
            # Production : SSL strict
            ssl_context.check_hostname = True
            ssl_context.verify_mode = ssl.CERT_REQUIRED
            logger.info("Using strict SSL verification in production mode")
        
        return ssl_context

    def connect(self):
        try:
            credentials = pika.PlainCredentials(
                Config.RABBITMQ_USER, 
                Config.RABBITMQ_PASSWORD
            )
            
            if Config.is_rabbitmq_ssl:
                # Connexion SSL (AWS RabbitMQ ou RabbitMQ externe)
                logger.info(f"Connecting to RabbitMQ with SSL: {Config.rabbitmq_connection_url}")
                
                ssl_context = self._create_ssl_context()
                parameters = pika.URLParameters(Config.rabbitmq_connection_url)
                parameters.credentials = credentials
                parameters.ssl_options = pika.SSLOptions(ssl_context)
                
                self._connection = pika.BlockingConnection(parameters)
                
            else:
                # Connexion non-SSL (RabbitMQ interne Kubernetes)
                logger.info(f"Connecting to RabbitMQ without SSL: {Config.rabbitmq_connection_url}")
                
                if Config.RABBITMQ_URL:
                    # Utiliser l'URL complète
                    parameters = pika.URLParameters(Config.rabbitmq_connection_url)
                    parameters.credentials = credentials
                    self._connection = pika.BlockingConnection(parameters)
                else:
                    # Utiliser les paramètres individuels
                    connection_params = pika.ConnectionParameters(
                        host=Config.RABBITMQ_HOST,
                        port=int(Config.RABBITMQ_PORT),
                        credentials=credentials,
                        heartbeat=600,
                        blocked_connection_timeout=300
                    )
                    self._connection = pika.BlockingConnection(connection_params)
            
            self._channel = self._connection.channel()
            
            # Déclarer les queues avec options de durabilité
            self._channel.queue_declare(
                queue=Config.RABBITMQ_TASK_QUEUE, 
                durable=True,
                arguments={'x-message-ttl': 300000}  # TTL 5 minutes
            )
            self._channel.queue_declare(
                queue=Config.RABBITMQ_RESPONSE_QUEUE, 
                durable=True,
                arguments={'x-message-ttl': 300000}
            )
            
            logger.info("Successfully connected to RabbitMQ")
            return True
            
        except Exception as e:
            logger.error(f"Failed to connect to RabbitMQ: {str(e)}")
            self.reconnect()
            return False

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
                        if not self.connect():
                            continue

                    # Configuration du QoS pour limiter les messages non-ackés
                    self._channel.basic_qos(prefetch_count=1)
                    
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
                except KeyboardInterrupt:
                    logger.info("Stopping consumer...")
                    self._should_reconnect = False
                    break
                except Exception as e:
                    logger.error(f"Unexpected error: {str(e)}")
                    time.sleep(2)

        if not self._started:
            consumer_thread = Thread(target=_consume, daemon=True)
            consumer_thread.start()
            self._started = True
            logger.info("Consumer thread started")

    def _process_message(self, ch, method, properties, body):
        """Traiter les messages RabbitMQ dans le contexte Flask."""
        with self.app.app_context():
            try:
                logger.info(f"Received message: {body}")
                message = json.loads(body)
                action = message.get("action")
                data = message.get("data")

                logger.info(f"Processing action: {action} with data: {data}")

                if action == "create_order":
                    # Validation des données
                    required_fields = ["user_id", "number_of_items", "total_amount"]
                    if not all(field in data for field in required_fields):
                        raise ValueError(f"Missing required fields: {required_fields}")
                    
                    order = Order.create(
                        user_id=data["user_id"], 
                        number_of_items=data["number_of_items"], 
                        total_amount=data["total_amount"]
                    )
                    
                    response = {
                        "status": "success",
                        "message": "Facture créée avec succès.",
                        "data": order.to_dict(),
                        "correlation_id": properties.correlation_id
                    }

                    logger.info(f"Order created successfully: {response}")

                else:
                    response = {
                        "status": "error",
                        "message": f"Action non reconnue: {action}",
                        "correlation_id": properties.correlation_id
                    }
                    logger.warning(f"Unknown action: {action}")

                # Envoyer la réponse si reply_to est spécifié
                if properties.reply_to:
                    ch.basic_publish(
                        exchange="",
                        routing_key=properties.reply_to,
                        properties=pika.BasicProperties(
                            correlation_id=properties.correlation_id,
                            content_type='application/json'
                        ),
                        body=json.dumps(response),
                    )
                    logger.info(f"Response sent to {properties.reply_to}")

                # Acquitter le message
                ch.basic_ack(delivery_tag=method.delivery_tag)

            except json.JSONDecodeError as e:
                logger.error(f"Invalid JSON message: {str(e)}")
                ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
            except ValueError as e:
                logger.error(f"Validation error: {str(e)}")
                ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
            except Exception as e:
                logger.error(f"Processing error: {str(e)}")
                # Requeue le message en cas d'erreur système
                ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)

    def close(self):
        """Fermer proprement la connexion RabbitMQ."""
        self._should_reconnect = False
        try:
            if self._channel and self._channel.is_open:
                self._channel.stop_consuming()
            if self._connection and self._connection.is_open:
                self._connection.close()
            logger.info("RabbitMQ connection closed gracefully")
        except Exception as e:
            logger.error(f"Error closing RabbitMQ connection: {str(e)}")


# Initialisation globale
consumer = None


def register_routes(app):
    global consumer

    try:
        # Initialisation du consommateur RabbitMQ
        consumer = RabbitMQConsumer(app)
        consumer.start_consuming()
        logger.info("RabbitMQ consumer registered successfully")
        
        # Nettoyage à la fermeture de l'application
        @app.teardown_appcontext
        def shutdown_rabbitmq(exception=None):
            if consumer:
                consumer.close()
                
    except Exception as e:
        logger.error(f"Failed to register RabbitMQ consumer: {str(e)}")
        raise