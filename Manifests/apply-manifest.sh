#!/bin/bash

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    exit 1
fi

# Apply orchestrator namespace first - skip validation and TLS verification
kubectl apply -f orchestrator-namespace.yaml --validate=false

# Apply all yaml and yml files in the current directory
echo "Applying Kubernetes manifests..."
for file in *.{yaml,yml}; do
    if [ -f "$file" ]; then
        echo "Applying $file..."
        kubectl apply -f "$file" --validate=false
        if [ $? -ne 0 ]; then
            echo "Error applying $file. This might be due to TLS certificate issues."
            echo "Try running: kubectl config set-cluster default --insecure-skip-tls-verify=true"
            exit 1
        fi
    fi
done

echo "All manifests applied successfully"

# Verify resources were created
echo "Verifying resources in orchestrator namespace..."
kubectl get all -n orchestrator
