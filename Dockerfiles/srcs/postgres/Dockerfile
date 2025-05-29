FROM alpine:3.21.3

# Installation avec cleanup immédiat
RUN apk add --no-cache \
    postgresql15 \
    postgresql15-client \
    bash \
    su-exec \
    && mkdir -p /var/lib/postgresql/data \
    && chown -R postgres:postgres /var/lib/postgresql \
    && chmod 700 /var/lib/postgresql/data

# Script d'initialisation
COPY init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init.sh

# Configuration
WORKDIR /var/lib/postgresql
ENV PGDATA=/var/lib/postgresql/data
EXPOSE 5432

# Démarrer en tant que root pour permettre à Kubernetes de gérer les permissions
ENTRYPOINT ["/usr/local/bin/init.sh"]