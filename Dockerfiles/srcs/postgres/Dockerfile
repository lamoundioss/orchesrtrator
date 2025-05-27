FROM alpine:3.21.3

# Installation de PostgreSQL avec client
RUN apk add --no-cache postgresql15 postgresql15-client bash

# Création de l'utilisateur postgres avec UID 999
RUN addgroup -g 999 postgres && \
    adduser -u 999 -G postgres -D -s /bin/bash postgres

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