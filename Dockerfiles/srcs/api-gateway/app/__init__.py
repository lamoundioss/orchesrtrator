from flask import Flask
from flask_cors import CORS
from .config import Config
from .routes import register_routes


def create_app(config=Config):
    app = Flask(__name__)
    app.config.from_object(config)
    CORS(app, origins="*")

    # Enregistrer les routes
    register_routes(app)

    return app
