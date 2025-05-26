import os


class Config:
    SQLALCHEMY_DATABASE_URI = (
        "postgresql://{user}:{password}@{host}:{port}/{dbname}".format(
            user=os.environ.get("POSTGRES_USER"),
            password=os.environ.get("POSTGRES_PASSWORD"),
            dbname=os.environ.get("POSTGRES_DB"),
            host=os.environ.get("INVENTORY_DATABASE_HOST"),
            port=os.environ.get("DB_PORT"),
        )
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    DEBUG = True
