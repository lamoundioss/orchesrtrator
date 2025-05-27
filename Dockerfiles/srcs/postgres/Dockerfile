FROM alpine:3.21.3

# Installer PostgreSQL et bash
RUN apk add --no-cache postgresql15 postgresql15-client bash shadow

# Forcer seulement l'UID si le GID 999 existe déjà
RUN usermod -u 999 postgres || echo "UID not changed"

# Créer les répertoires PostgreSQL
RUN mkdir -p /run/postgresql && \
    mkdir -p /var/lib/postgresql/data && \
    chown -R postgres:postgres /run/postgresql /var/lib/postgresql

# Script d'initialisation
COPY init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init.sh

EXPOSE 5432

USER postgres
ENTRYPOINT ["/usr/local/bin/init.sh"]
CMD ["postgres", "-D", "/var/lib/postgresql/data"]
