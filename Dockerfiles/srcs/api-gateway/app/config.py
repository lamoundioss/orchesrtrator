import os


class Config:
    SECRET_KEY = os.getenv("SECRET_KEY")
    DEBUG = True
    RABBITMQ_HOST = os.getenv("RABBITMQ_HOST")
    RABBITMQ_USER = os.getenv("RABBITMQ_DEFAULT_USER")
    RABBITMQ_PASSWORD = os.getenv("RABBITMQ_DEFAULT_PASS")
    RABBITMQ_TASK_QUEUE = "billing_queue"
    RABBITMQ_RESPONSE_QUEUE = "response_queue"
    INVENTORY_SERVICE_URL= os.getenv("INVENTORY_SERVICE_URL")
