# Play-with-containers

## Introduction

Ce projet illustre une architecture microservices conteneurisée pour une plateforme de streaming vidéo, construite avec Docker et Docker Compose. Le système comprend trois services principaux (API Gateway, Inventory, Billing) communicant via des APIs REST et des files de messages RabbitMQ. Chaque composant fonctionne dans un conteneur isolé pour garantir modularité, scalabilité et reproductibilité.

Pour une compréhension détaillée du projet, vous pouvez consulter le dépôt de référence : [crudmaster](https://github.com/01-edu/crud-master-py).

## Composants de l'Architecture

### 1. API Gateway
- **Port** : 3000
- **Rôle** : Point d'entrée central pour toutes les requêtes client. Route les requêtes vers les services Inventory et Billing, et utilise RabbitMQ pour les opérations asynchrones (par exemple, paiements).
- **Dépendances** :
  - RabbitMQ (messagerie)
  - Service Inventory (via réseau interne)
  - Service Billing (via réseau interne)

### 2. Service Inventory
- **Port** : 8080 (interne)
- **Base de données** : PostgreSQL (base `movies`) sur le port 5433
- **Rôle** : Gère le catalogue de films (ajout, suppression, consultation).
- **Dépendances** :
  - Base de données PostgreSQL `inventory-database`

### 3. Service Billing
- **Port** : 8080 (interne)
- **Base de données** : PostgreSQL (base `orders`) sur le port 5432
- **Rôle** : Traite les paiements et gère les commandes des utilisateurs.
- **Dépendances** :
  - Base de données PostgreSQL `billing-database`
  - RabbitMQ (file de messages pour les transactions)

### 4. RabbitMQ
- **Ports** : 5672 (messagerie), 15672 (interface de gestion)
- **Rôle** : Broker de messages pour les communications asynchrones entre l'API Gateway et le service Billing.

### 5. Bases de données PostgreSQL
- **Billing Database** : Base `orders` pour les données de commandes (port 5432).
- **Inventory Database** : Base `movies` pour le catalogue de films (port 5433).

## Prérequis

- **Docker Engine** : Version 20.10 ou supérieure
- **Docker Compose** : Version 2.0 ou supérieure
- **Système d'exploitation** : Linux, macOS, ou Windows (avec WSL2 pour Windows)
- **Matériel** :
  - 4GB RAM minimum
  - 2 cœurs CPU minimum
- **Outils recommandés** :
  - `git` pour cloner le dépôt
  - Un éditeur de texte pour configurer le fichier `.env`
- **Espace disque** : ~2GB pour les images Docker et les volumes

## Structure du Projet

Le projet est organisé comme suit :
```
play-with-containers/
├── docker-compose.yml
├── .env
├── README.md
└── srcs/
    ├── api-gateway/
    │   ├── Dockerfile
    │   ├── requirements.txt
    │   ├── server.py
    │   └── ...
    ├── billing-app/
    │   ├── Dockerfile
    │   ├── requirements.txt
    │   ├── server.py
    │   └── ...
    ├── inventory-app/
    │   ├── Dockerfile
    │   ├── requirements.txt
    │   ├── server.py
    │   └── ...
```

## Configuration

1. **Cloner le dépôt** :
   ```bash
   git clone https://learn.zone01dakar.sn/git/fatouthiam2/play-with-containers.git
   cd play-with-containers
   ```

2. **Créer le fichier `.env`** :
   Au cas ou le fichier `.env` n'est pas disponible dans les fichiers clonés, créez le à la racine du projet avec le contenu suivant :
   ```ini
   RABBITMQ_HOST=<votre nom de conteneur rabbitmq>
   RABBITMQ_DEFAULT_USER=<votre user rabbitmq>
   RABBITMQ_DEFAULT_PASS=<votre mot de passe rabbitmq>

   BILLING_DATABASE_HOST=<votre nom de conteneur de la base de donnee billing>
   INVENTORY_DATABASE_HOST=<votre nom de conteneur de la base de donnee inventory>

   DB_PORT=<votre port postgres>
   POSTGRES_USER=<votre user postgres>
   POSTGRES_PASSWORD=<votre password postgres>
   POSTGRES_DB=orders

   INVENTORY_SERVICE_URL=http://<votre nom de conteneur inventory>:<votre port de communication>/<votre nom de base de donnee inventory>
   ```
   - `RABBITMQ_HOST` : Nom du service RabbitMQ dans le réseau Docker.
   - `BILLING_DATABASE_HOST` et `INVENTORY_DATABASE_HOST` : Noms des services PostgreSQL.
   - `INVENTORY_SERVICE_URL`: URLs internes pour l'API Gateway.

## Installation

1. **Construire et lancer les services** :
   ```bash
   docker-compose up -d --build
   ```
   Cette commande :
   - Construit les images pour `api-gateway-app`, `billing-app`, et `inventory-app`.
   - Lance tous les services (`rabbitmq`, `billing-database`, `inventory-database`).

2. **Vérifier l'état des services** :
   ```bash
   docker-compose ps
   ```
   Tous les services doivent être dans l'état `Up` avec les healthchecks marqués `(healthy)`.

3. **Consulter les logs (optionnel)** :
   Pour diagnostiquer un service spécifique :
   ```bash
   docker-compose logs -f <nom_du_service>
   ```
   Exemple : `docker-compose logs -f api-gateway-app`.

## Utilisation

### Points d'accès
| Service               | Port Externe | Port Interne | Accessible Depuis          |
|-----------------------|--------------|--------------|----------------------------|
| API Gateway           | 3000         | 3000         | Public (localhost:3000)    |
| Billing Database      |   -          | 5432         | Interne                    |
| Inventory Database    |   -          | 5432         | Interne                    |
| RabbitMQ (messagerie) |   -          | 5672         | Interne                    |
| RabbitMQ (gestion)    |   -          | 15672        | Public                     |

### Tester l'API Gateway
L'API Gateway est le point d'entrée principal. Exemples de requêtes :
- **Lister les films** :
  ```bash
  curl http://localhost:3000/api/movies
  ```
- **Créer une commande** (exemple, dépend de l'implémentation) :
  ```bash
  curl -X POST http://localhost:3000/api/billing -H "Content-Type: application/json" -d '{"film_id": 1, "user_id": "user123"}'
  ```

## Maintenance

### Surveillance de santé
Tous les services incluent des healthchecks :
- **PostgreSQL** : Vérifie la disponibilité des bases billing_db et inventory_db.
- **RabbitMQ** : Contrôle la réactivité du broker.
- **Microservices** : Dépendent des services sains avant de démarrer.

### Sauvegarde des bases
- Sauvegarder `billing-database` :
  ```bash
  docker-compose exec billing-database pg_dump -U postgres orders > billing_backup.sql
  ```
- Sauvegarder `inventory-database` :
  ```bash
  docker-compose exec inventory-database pg_dump -U postgres movies > inventory_backup.sql
  ```

### Mise à l'échelle
Pour ajouter des instances du service Inventory :
```bash
docker-compose up -d --scale inventory-app=3
```
**Note** : Assurez-vous que l'API Gateway est configuré pour gérer plusieurs instances (par exemple, via un load balancer ou une découverte de services).

### Arrêt et nettoyage
- Arrêter les services :
  ```bash
  docker-compose stop
  ```
- Arrêter et supprimer les conteneurs :
  ```bash
  docker-compose down
  ```
- Supprimer les volumes (attention : efface les données persistantes) :
  ```bash
  docker-compose down -v
  ```

### Mise à jour des dépendances
Si les fichiers `requirements.txt` sont modifiés :
1. Reconstruisez les images :
   ```bash
   docker-compose build
   ```
2. Redémarrez les services :
   ```bash
   docker-compose up -d
   ```

## Dépannage

- **L'API Gateway ne répond pas sur `localhost:3000`** :
  - Vérifiez les logs : `docker-compose logs api-gateway-app`.
  - Assurez-vous que le port 3000 n'est pas utilisé par une autre application.
- **Erreur de connexion à PostgreSQL** :
  - Vérifiez les logs : `docker-compose logs billing-database` ou `inventory-database`.
  - Confirmez que les variables `.env` (`BILLING_DATABASE_HOST`, `INVENTORY_DATABASE_HOST`) sont correctes.
- **RabbitMQ inaccessible** :
  - Vérifiez les identifiants dans `.env` (`RABBITMQ_DEFAULT_USER`, `RABBITMQ_DEFAULT_PASS`).
  - Testez la connexion : `docker-compose exec rabbitmq rabbitmqctl status`.
- **Un service ne démarre pas** :
  - Vérifiez l'état : `docker-compose ps`.
  - Consultez les logs pour identifier l'erreur.

## Architecture Réseau

- **Réseau** : `play_with_containers_network` (bridge), connectant tous les services.
- **Communication** :
  - Les services communiquent via leurs noms (`api-gateway-app`, `billing-app`, `inventory-app`, `rabbitmq`, `billing-database`, `inventory-database`).
  - Exemple : L'API Gateway appelle `INVENTORY_SERVICE_URL` de notre `.env` pour les films.
- **Ports exposés** :
  - Public : API Gateway (3000), RabbitMQ Management (15672).
  - Interne : Billing (8080), Inventory (8080), PostgreSQL (5432), RabbitMQ (5672, 15672).

## Stockage Persistant

- **Volumes** :
  - `billing-database` : Données de la base inventory.
  - `inventory-database` : Données de la base billing.
  - `api-gateway-app` : Persistance des messages RabbitMQ.
- Les volumes garantissent que les données sont conservées entre les redémarrages.

## Conclusion

Ce projet démontre une architecture microservices robuste avec :
- **Isolation** : Chaque service dans un conteneur dédié.
- **Scalabilité** : Mise à l'échelle possible (ex. `inventory-app`).
- **Persistance** : Données sauvegardées via volumes Docker.
- **Reproductibilité** : Déploiement simplifié avec Docker Compose.

### Améliorations futures
- Ajouter un monitoring (Prometheus, Grafana).
- Migrer vers Kubernetes pour la production.
- Implémenter des pipelines CI/CD.
- Ajouter des tests automatisés pour les APIs.

Ce projet est une base solide pour explorer les microservices et la conteneurisation, avec des possibilités d'extension pour des cas d'usage réels.