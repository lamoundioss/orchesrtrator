FROM debian:12-slim AS builder

# Installation des dépendances de build
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    rabbitmq-server \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Stage final - image de production
FROM debian:12-slim

# Installer seulement les dépendances runtime nécessaires
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    rabbitmq-server \
    curl \
    ca-certificates \
    gosu \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Variables d'environnement avec valeurs par défaut
ENV RABBITMQ_DEFAULT_USER=${RABBITMQ_DEFAULT_USER:-passer} \
    RABBITMQ_DEFAULT_PASS=${RABBITMQ_DEFAULT_PASS:-password} \
    RABBITMQ_NODENAME=rabbit@localhost \
    RABBITMQ_CONFIG_FILE=/etc/rabbitmq/rabbitmq.conf \
    RABBITMQ_LOGS=- \
    RABBITMQ_LOG_BASE=/var/log/rabbitmq \
    RABBITMQ_MNESIA_BASE=/var/lib/rabbitmq/mnesia \
    RABBITMQ_PID_FILE=/var/lib/rabbitmq/rabbitmq.pid \
    DEBIAN_FRONTEND=noninteractive

# Créer les répertoires nécessaires avec les bonnes permissions
RUN mkdir -p /var/lib/rabbitmq /var/log/rabbitmq /etc/rabbitmq && \
    chown -R rabbitmq:rabbitmq /var/lib/rabbitmq /var/log/rabbitmq /etc/rabbitmq

# Copier les fichiers de configuration avec les bonnes permissions
COPY --chown=rabbitmq:rabbitmq rabbitmq.conf /etc/rabbitmq/rabbitmq.conf
COPY --chown=rabbitmq:rabbitmq --chmod=755 init-rabbitmq.sh /usr/local/bin/init.sh

# Activer les plugins RabbitMQ essentiels
RUN rabbitmq-plugins enable rabbitmq_management rabbitmq_prometheus

# Exposer les ports
EXPOSE 5672 15672

# Utilisateur non-root pour la sécurité
USER rabbitmq

# Volume pour la persistance des données
VOLUME ["/var/lib/rabbitmq", "/var/log/rabbitmq"]

# Point d'entrée
ENTRYPOINT ["/usr/local/bin/init.sh"]