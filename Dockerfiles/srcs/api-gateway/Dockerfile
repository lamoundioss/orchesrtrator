# Multi-stage build pour réduire la taille finale
FROM alpine:3.21.3 AS builder

RUN apk add --no-cache \
    python3 \
    py3-pip \
    py3-virtualenv \
    gcc \
    musl-dev \
    python3-dev \
    libffi-dev

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /usr/src
RUN chown -R appuser:appgroup /usr/src

COPY --chown=appuser:appgroup requirements.txt ./

USER appuser

# Créer le venv et installer les dépendances
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Stage final - image de production
FROM alpine:3.21.3

# Installer seulement les dépendances runtime nécessaires
RUN apk add --no-cache \
    python3 \
    libffi

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /usr/src

# Copier le venv depuis le stage builder
COPY --from=builder --chown=appuser:appgroup /usr/src/venv ./venv

# Copier le code source
COPY --chown=appuser:appgroup . .

USER appuser

EXPOSE 3000

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/usr/src/venv/bin:$PATH"

CMD ["python", "server.py"]