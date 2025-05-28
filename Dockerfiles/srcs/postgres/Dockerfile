FROM alpine:3.21.3

# Installation avec cleanup immédiat
RUN apk add --no-cache \
    postgresql15 \
    postgresql15-client \
    bash \
    shadow \
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

ENTRYPOINT ["/usr/local/bin/init.sh"]
CMD ["postgres", "-D", "/var/lib/postgresql/data"]