FROM alpine:3.21.3

WORKDIR /usr/src/

# Installer Python 3, pip et les dépendances nécessaires pour PostgreSQL et compilation
RUN apk add --no-cache \ 
    python3 \
    py3-pip \
    py3-virtualenv

COPY requirements.txt ./

# Créer un environnement virtuel et l'activer
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip3 install --no-cache-dir -r requirements.txt

COPY . .

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

RUN chown -R appuser:appgroup /usr/src

USER appuser

EXPOSE 3000

CMD ["venv/bin/python", "server.py"]
