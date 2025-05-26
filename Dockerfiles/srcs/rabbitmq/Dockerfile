FROM debian:12

RUN apt-get update && \
    apt-get install -y rabbitmq-server

ENV RABBITMQ_DEFAULT_USER=${RABBITMQ_DEFAULT_USER}
ENV RABBITMQ_DEFAULT_PASS=${RABBITMQ_DEFAULT_PASS}

COPY init-rabbitmq.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

EXPOSE 5672 15672

ENTRYPOINT ["/usr/local/bin/init.sh"]
