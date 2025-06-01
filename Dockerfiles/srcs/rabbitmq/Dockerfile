FROM debian:12

# Installation des dépendances
RUN apt-get update && \
    apt-get install -y \
    rabbitmq-server \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Variables d'environnement avec valeurs par défaut
ENV RABBITMQ_DEFAULT_USER=${RABBITMQ_DEFAULT_USER:-admin}
ENV RABBITMQ_DEFAULT_PASS=${RABBITMQ_DEFAULT_PASS:-password}
ENV RABBITMQ_NODENAME=rabbit@localhost
ENV RABBITMQ_CONFIG_FILE=/etc/rabbitmq/rabbitmq.conf

# Copier les scripts et configurations
COPY init-rabbitmq.sh /usr/local/bin/init.sh
COPY rabbitmq.conf /etc/rabbitmq/rabbitmq.conf

# Permissions
RUN chmod +x /usr/local/bin/init.sh && \
    chown -R rabbitmq:rabbitmq /var/lib/rabbitmq && \
    chown -R rabbitmq:rabbitmq /etc/rabbitmq

# Ports
EXPOSE 5672 15672 25672

# Utilisateur non-root pour la sécurité
USER rabbitmq

# Point d'entrée
ENTRYPOINT ["/usr/local/bin/init.sh"]