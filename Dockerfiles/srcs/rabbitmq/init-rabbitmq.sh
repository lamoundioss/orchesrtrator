#!/bin/bash
set -e

# Démarrer RabbitMQ en arrière-plan
rabbitmq-server -detached

# Attendre que RabbitMQ soit prêt
echo "Attente de RabbitMQ..."
until rabbitmqctl status >/dev/null 2>&1; do
  sleep 5
done

# Activer l'interface web de gestion
rabbitmq-plugins enable --offline rabbitmq_management

# Ajouter l'utilisateur si non existant
if ! rabbitmqctl list_users | grep -q "${RABBITMQ_DEFAULT_USER}"; then
  rabbitmqctl add_user "$RABBITMQ_DEFAULT_USER" "$RABBITMQ_DEFAULT_PASS" && \
  rabbitmqctl set_user_tags "$RABBITMQ_DEFAULT_USER" administrator && \
  rabbitmqctl set_permissions -p / "$RABBITMQ_DEFAULT_USER" ".*" ".*" ".*"
fi

# Redémarrer RabbitMQ au premier plan
rabbitmqctl stop
exec rabbitmq-server
