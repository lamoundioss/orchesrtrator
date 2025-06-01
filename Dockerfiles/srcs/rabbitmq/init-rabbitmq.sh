#!/bin/bash
set -e

# Function pour logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Fonction pour attendre que RabbitMQ soit prêt
wait_for_rabbitmq() {
    local max_attempts=30
    local attempt=1
    
    log "Attente de RabbitMQ..."
    while [ $attempt -le $max_attempts ]; do
        if rabbitmqctl status >/dev/null 2>&1; then
            log "RabbitMQ est prêt !"
            return 0
        fi
        log "Tentative $attempt/$max_attempts - En attente..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log "ERREUR: RabbitMQ n'a pas démarré dans les temps"
    exit 1
}

# Fonction pour nettoyer à l'arrêt
cleanup() {
    log "Arrêt de RabbitMQ..."
    rabbitmqctl stop_app >&/dev/null || true
    rabbitmqctl stop >&/dev/null || true
    exit 0
}

# Gérer les signaux d'arrêt
trap cleanup SIGTERM SIGINT

# Démarrer RabbitMQ en arrière-plan
log "Démarrage de RabbitMQ..."
rabbitmq-server -detached

# Attendre que RabbitMQ soit prêt
wait_for_rabbitmq

# Activer les plugins nécessaires
log "Activation des plugins..."
rabbitmq-plugins enable rabbitmq_management rabbitmq_management_agent

# Configurer l'utilisateur admin
log "Configuration de l'utilisateur: $RABBITMQ_DEFAULT_USER"

# Supprimer l'utilisateur guest par défaut (sécurité)
if rabbitmqctl list_users | grep -q "guest"; then
    log "Suppression de l'utilisateur guest par défaut"
    rabbitmqctl delete_user guest || true
fi

# Ajouter l'utilisateur admin s'il n'existe pas
if ! rabbitmqctl list_users | grep -q "$RABBITMQ_DEFAULT_USER"; then
    log "Création de l'utilisateur administrateur"
    rabbitmqctl add_user "$RABBITMQ_DEFAULT_USER" "$RABBITMQ_DEFAULT_PASS"
    rabbitmqctl set_user_tags "$RABBITMQ_DEFAULT_USER" administrator
    rabbitmqctl set_permissions -p / "$RABBITMQ_DEFAULT_USER" ".*" ".*" ".*"
else
    log "L'utilisateur $RABBITMQ_DEFAULT_USER existe déjà"
    # Mettre à jour le mot de passe au cas où
    rabbitmqctl change_password "$RABBITMQ_DEFAULT_USER" "$RABBITMQ_DEFAULT_PASS"
fi

# Arrêter RabbitMQ pour le redémarrage propre
log "Redémarrage de RabbitMQ au premier plan..."
rabbitmqctl stop

# Attendre un peu
sleep 2

# Démarrer RabbitMQ au premier plan
log "RabbitMQ configuré et prêt !"
exec rabbitmq-server