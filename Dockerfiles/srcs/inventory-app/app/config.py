import os


class Config:
    SQLALCHEMY_DATABASE_URI = (
        "postgresql://{user}:{password}@{host}/{dbname}".format(
            user=os.environ.get("POSTGRES_USER"),
            password=os.environ.get("POSTGRES_PASSWORD"),
            dbname=os.environ.get("POSTGRES_DB"),
            host=os.environ.get("INVENTORY_DATABASE_HOST"),
        )
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    DEBUG = True
