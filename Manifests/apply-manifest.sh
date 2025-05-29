#!/bin/bash

set -e

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    exit 1
fi

# Apply orchestrator namespace
kubectl apply -f orchestrator-namespace.yaml --validate=false

# Apply all YAML manifests
echo "Applying Kubernetes manifests..."
for file in *.{yaml,yml}; do
    if [ -f "$file" ]; then
        echo "Applying $file..."
        kubectl apply -f "$file" --validate=false
    fi
done

echo "✅ All manifests applied successfully"

# Verify resources in orchestrator namespace
echo "🔍 Verifying resources..."
kubectl get all -n orchestrator

# Automatically patch the Traefik deployment to expose the dashboard (if not done)
echo "🔧 Patching Traefik deployment to enable dashboard on port 8080..."

kubectl patch deployment traefik -n kube-system \
  --type='json' \
  -p='[
    {
      "op": "add",
      "path": "/spec/template/spec/containers/0/args/-",
      "value": "--api.insecure=true"
    },
    {
      "op": "add",
      "path": "/spec/template/spec/containers/0/ports/-",
      "value": {
        "containerPort": 8080,
        "name": "dashboard",
        "protocol": "TCP"
      }
    }
  ]' || echo "⚠️  Warning: Patch might already exist or failed."

# Wait for deployment to roll out
echo "⏳ Waiting for Traefik to roll out..."
kubectl rollout status deployment/traefik -n kube-system

# Launch port-forward in background
echo "🚀 Launching port-forward for Traefik dashboard on http://localhost:8080 ..."
kubectl port-forward svc/traefik -n kube-system 8080:8080 >/dev/null 2>&1 &

echo "✅ Setup complete. Traefik dashboard should be accessible at: http://localhost:8080"
