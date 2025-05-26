# Movie App Kubernetes Setup Guide

## Prerequisites

Before you begin, ensure you have the following installed:
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) (6.0 or newer)
- [Vagrant](https://www.vagrantup.com/downloads) (2.2.0 or newer)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) (compatible with K3s v1.21+)

## Architecture Overview

This project deploys a microservices architecture on Kubernetes (K3s), consisting of:

- **API Gateway**: Entry point for all requests
- **Inventory Service**: Manages movie inventory
- **Billing Service**: Handles billing operations
- **RabbitMQ**: Message broker for service communication
- **PostgreSQL Databases**: Separate databases for inventory and billing

## Cluster Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd movie-app
```

### 2. Create and Start the Cluster

```bash
chmod +x orchestrator.sh
./orchestrator.sh create
```

This command will:
- Create two virtual machines: master and agent
- Install K3s on both machines
- Configure them as a Kubernetes cluster
- Apply all Kubernetes manifests

### 3. Verify the Cluster

```bash
./orchestrator.sh status
```

## Cluster Management

### Starting the Cluster

If you've stopped the cluster and want to start it again:

```bash
./orchestrator.sh start
```

### Stopping the Cluster

To stop the VMs without destroying them:

```bash
./orchestrator.sh stop
```

### Destroying the Cluster

To completely remove the cluster:

```bash
./orchestrator.sh destroy
```

## Accessing Services

### API Gateway

The API Gateway is exposed as a NodePort service on port 30000. You can access it at:

```
http://<vm-ip>:30000
```

Where `<vm-ip>` is the IP of the master VM (typically 192.168.56.10).

### Kubernetes Dashboard (Bonus)

If you've deployed the Kubernetes Dashboard (bonus), you can access it by:

1. Getting the token:
   ```bash
   kubectl -n kubernetes-dashboard describe secret admin-user-token | grep '^token'
   ```

2. Starting the kubectl proxy:
   ```bash
   kubectl proxy
   ```

3. Accessing the dashboard at:
   ```
   http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
   ```

## Architecture Details

The application is deployed in a single namespace:
- `orchestrator`: Contains all components including API Gateway, Inventory App, Inventory Database, Billing App, Billing Database, and RabbitMQ

All services communicate within the same namespace, simplifying service discovery.

### Key Components:

- **Deployments with HPA**: API Gateway and Inventory App with autoscaling based on CPU usage (60%)
- **StatefulSets**: All databases and the Billing App for stateful operation
- **Persistent Volumes**: Configured for database persistence

## Troubleshooting

### Checking Logs

```bash
# API Gateway logs
kubectl logs -n orchestrator deployment/api-gateway

# Inventory App logs
kubectl logs -n orchestrator deployment/inventory-app

# Billing App logs
kubectl logs -n orchestrator statefulset/billing-app
```

### Checking Component Status

```bash
# Get all resources in orchestrator namespace
kubectl get all -n orchestrator
```

### Common Issues

1. **Services not starting**: Check the logs for detailed error messages
2. **Database connection issues**: Verify the ConfigMaps and Secrets are correctly configured
3. **Service discovery issues**: Check that all services are properly defined in the orchestrator namespace

## Security Notes

- Database passwords and credentials are stored as Kubernetes Secrets
- Do not commit secrets to your repository in plain text
- Use proper access controls for your Kubernetes cluster