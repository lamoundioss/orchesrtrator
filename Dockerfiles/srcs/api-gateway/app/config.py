import os


class Config:
    SECRET_KEY = os.getenv("SECRET_KEY")
    DEBUG = True
    
    # RabbitMQ Configuration - Support multi-environnements
    RABBITMQ_URL = os.getenv("RABBITMQ_URL")  # URL complète si fournie
    RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "rabbitmq-service")
    RABBITMQ_PORT = os.getenv("RABBITMQ_PORT", "5672")
    RABBITMQ_USER = os.getenv("RABBITMQ_DEFAULT_USER", "vagrant_user")
    RABBITMQ_PASSWORD = os.getenv("RABBITMQ_DEFAULT_PASS", "testinG321")
    
    # Queues
    RABBITMQ_TASK_QUEUE = "billing_queue"
    RABBITMQ_RESPONSE_QUEUE = "response_queue"
    
    # Services URLs
    INVENTORY_SERVICE_URL = os.getenv("INVENTORY_SERVICE_URL", "http://inventory-app:8080/movies")
    
    # Déterminer le type de connexion RabbitMQ
    @property
    def rabbitmq_connection_url(self):
        if self.RABBITMQ_URL:
            return self.RABBITMQ_URL
        else:
            return f"amqp://{self.RABBITMQ_HOST}:{self.RABBITMQ_PORT}"
    
    @property
    def is_rabbitmq_ssl(self):
        return self.rabbitmq_connection_url.startswith('amqps://')