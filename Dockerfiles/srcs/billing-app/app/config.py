import os


class Config:
    SQLALCHEMY_DATABASE_URI = (
        "postgresql://{user}:{password}@{host}/{dbname}".format(
            user=os.environ.get("POSTGRES_USER"),
            password=os.environ.get("POSTGRES_PASSWORD"),
            dbname=os.environ.get("POSTGRES_DB"),
            host=os.environ.get("BILLING_DATABASE_HOST"),
        )
    )
    SECRET_KEY = os.getenv("SECRET_KEY")
    DEBUG = True
    RABBITMQ_URL = os.getenv("RABBITMQ_HOST")
    RABBITMQ_USER = os.getenv("RABBITMQ_DEFAULT_USER")
    RABBITMQ_PASSWORD = os.getenv("RABBITMQ_DEFAULT_PASS")
    RABBITMQ_TASK_QUEUE = "billing_queue"
    RABBITMQ_RESPONSE_QUEUE = "response_queue"
