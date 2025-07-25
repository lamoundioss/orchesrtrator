# Multi-stage build pour réduire la taille finale
FROM alpine:3.21.3 AS builder

# Installer les dépendances de build (séparées des dépendances runtime)
RUN apk add --no-cache \
    python3 \
    py3-pip \
    py3-virtualenv \
    postgresql-dev \
    python3-dev \
    gcc \
    musl-dev \
    libffi-dev

# Définir le répertoire de travail
WORKDIR /usr/src

# Copier uniquement requirements.txt pour optimiser le cache Docker
COPY requirements.txt ./

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
    postgresql-libs \
    libffi

# Créer l'utilisateur
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Définir le répertoire de travail
WORKDIR /usr/src

# Copier le venv depuis le stage builder
COPY --from=builder --chown=appuser:appgroup /usr/src/venv ./venv

# Copier le code source
COPY --chown=appuser:appgroup . .

# Changer d'utilisateur
USER appuser

# Exposer le port
EXPOSE 8080

# Variables d'environnement
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/usr/src/venv/bin:$PATH"

# Healthcheck pour monitoring
# HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
#     CMD python -c "import requests; requests.get('http://localhost:8080/health')" || exit 1

# Utiliser exec form pour un meilleur signal handling
CMD ["python", "server.py"]