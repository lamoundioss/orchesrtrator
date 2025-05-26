import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))


import pytest
from app import create_app, db
from .models import User, Order
from app.config import Config

@pytest.fixture
def app():
    app = create_app(config=Config)  # Crée une instance de l'app avec la configuration de test
    """Fixture pour l'application Flask."""
    with app.app_context():
        # Crée les tables dans la base de données de test
        db.create_all()
    yield app
    # Nettoie après les tests
    with app.app_context():
        db.session.remove()
        db.drop_all()

@pytest.fixture
def client(app):
    """Fixture pour le client de test."""
    return app.test_client()

# Test pour la création d'un utilisateur
def test_create_user(client):
    """Tester la création d'un utilisateur."""
    response = client.post('/users/', json={
        "firstName": "John",
        "lastName": "Doe",
        "email": "johndoe@example.com",
        "password": "SecurePassword123"
    })
    assert response.status_code == 201
    data = response.get_json()
    assert "id" in data
    assert data["firstName"] == "John"
    assert data["lastName"] == "Doe"

# Test pour la récupération de tous les utilisateurs
def test_get_all_users(client):
    """Tester la récupération de tous les utilisateurs."""
    response = client.get('/users/')
    assert response.status_code == 200
    data = response.get_json()
    assert isinstance(data, list)

# Test pour récupérer un utilisateur par ID
def test_get_user_by_id(client):
    """Tester la récupération d'un utilisateur par ID."""
    # Créer un utilisateur pour la démonstration
    app = create_app(config=Config)
    with app.app_context():
        user = User.create("Alice", "Smith", "alice@example.com", "password123")
        response = client.get(f'/users/{user.id}')
        assert response.status_code == 200
        data = response.get_json()
        assert data["firstName"] == "Alice"
        assert data["lastName"] == "Smith"

# Test pour la mise à jour d'un utilisateur
def test_update_user(client):
    """Tester la mise à jour des informations d'un utilisateur."""
    app = create_app(config=Config)
    with app.app_context():
        user = User.create("Bob", "Johnson", "bob@example.com", "password123")
        response = client.put(f'/users/{user.id}', json={
            "firstName": "Bobby",
            "lastName": "Johnson",
            "email": "bobby@example.com",
            "password": "newpassword123"
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data["firstName"] == "Bobby"
        assert data["lastName"] == "Johnson"

# Test pour la suppression d'un utilisateur
def test_delete_user(client, app):
    """Tester la suppression d'un utilisateur."""
    # app = create_app(config=Config)
    with app.app_context():
        user = User.create("Charlie", "Brown", "charlie@example.com", "password123")
        assert user is not None 
        assert user.id is not None

        response = client.delete(f'/users/{user.id}')
        assert response.status_code == 200
        data = response.get_json()
        assert data["message"] == "Utilisateur supprimé."

# Test pour la création d'une commande
def test_create_order(client):
    """Tester la création d'une commande."""
    app = create_app(config=Config)
    with app.app_context():
        user = User.create("John", "Doe", "johndoe@example.com", "password123")
        response = client.post('/orders/', json={
            "user_id": user.id,
            "number_of_items": 3,
            "total_amount": 150.00
        })
        assert response.status_code == 201
        data = response.get_json()
        assert "id" in data
        assert data["user_id"] == user.id
        assert data["total_amount"] == 150.00
