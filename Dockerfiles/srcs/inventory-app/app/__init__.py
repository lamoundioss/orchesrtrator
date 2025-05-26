from flask import Flask
from flask_cors import CORS

from .config import Config
from .extensions import db
from .routes import register_routes


def create_app(config=Config):
    app = Flask(__name__)
    app.config.from_object(config)

    db.init_app(app)
    CORS(app, origins="*")

    with app.app_context():
        db.create_all()  # Create tables

    register_routes(app)

    return app
