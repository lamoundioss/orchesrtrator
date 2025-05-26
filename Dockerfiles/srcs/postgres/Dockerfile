FROM alpine:3.21.3

# Installation de PostgreSQL avec client
RUN apk add --no-cache postgresql15 postgresql15-client bash

# Création des répertoires nécessaires
RUN mkdir -p /run/postgresql && \
    mkdir -p /var/lib/postgresql/data && \
    chown -R postgres:postgres /run/postgresql /var/lib/postgresql

# Copie du script d'initialisation
COPY init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init.sh

EXPOSE 5432

USER postgres
ENTRYPOINT ["/usr/local/bin/init.sh"]
CMD ["postgres", "-D", "/var/lib/postgresql/data"]