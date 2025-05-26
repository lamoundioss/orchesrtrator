FROM alpine:3.21.3

WORKDIR /usr/src/

# Installer Python, pip, venv, PostgreSQL dev et les outils de compilation
RUN apk add --no-cache \
    python3 \
    py3-pip \
    py3-virtualenv \
    postgresql-dev \
    python3-dev 

COPY requirements.txt ./

# Créer un environnement virtuel et l'activer
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip3 install --no-cache-dir -r requirements.txt

COPY . .

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

RUN chown -R appuser:appgroup /usr/src

USER appuser

EXPOSE 8080

CMD ["venv/bin/python", "server.py"]
