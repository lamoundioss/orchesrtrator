import os


class Config:
    # Database Configuration
    SQLALCHEMY_DATABASE_URI = (
        "postgresql://{user}:{password}@{host}:{port}/{dbname}".format(
            user=os.environ.get("BILLING_DB_USER"),
            password=os.environ.get("BILLING_DB_PASSWORD"),
            dbname=os.environ.get("BILLING_DB_NAME"),
            host=os.environ.get("BILLING_DB_HOST", "billing-database-service"),
            port=os.environ.get("BILLING_DB_PORT", "5432"),
        )
    )
    
    # App Configuration
    SECRET_KEY = os.getenv("SECRET_KEY", "default-secret-key")
    DEBUG = True
    
    # RabbitMQ Configuration - Support multi-environnements
    RABBITMQ_URL = os.getenv("RABBITMQ_URL")  # URL complète si fournie
    RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "rabbitmq-service")
    RABBITMQ_PORT = os.getenv("RABBITMQ_PORT", "5672")
    RABBITMQ_USER = os.getenv("RABBITMQ_DEFAULT_USER")
    RABBITMQ_PASSWORD = os.getenv("RABBITMQ_DEFAULT_PASS")
    
    # Queues
    RABBITMQ_TASK_QUEUE = "billing_queue"
    RABBITMQ_RESPONSE_QUEUE = "response_queue"
    
    # @property
    # def rabbitmq_connection_url(self):
    #     """Détermine l'URL de connexion RabbitMQ."""
    #     if self.RABBITMQ_URL:
    #         return self.RABBITMQ_URL
    #     else:
    #         return f"amqp://{self.RABBITMQ_HOST}:{self.RABBITMQ_PORT}"
    
    @property
    def is_rabbitmq_ssl(self):
        """Détermine si la connexion RabbitMQ utilise SSL."""
        return self.rabbitmq_connection_url.startswith('amqps://')