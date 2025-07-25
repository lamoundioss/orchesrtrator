#!/bin/bash

# Update and install dependencies
apt-get update
apt-get install -y curl

# Get the K3s token from the master node
TOKEN=$(cat /vagrant/token)

# Set worker IP address (using the private network interface)
workerIP="192.168.56.60"

# Install K3s as an agent (worker) with proper network configuration
export INSTALL_K3S_EXEC="--flannel-iface=enp0s8 --node-ip=${workerIP} --node-name=agent"
curl -sfL https://get.k3s.io | K3S_URL="https://192.168.56.50:6443" K3S_TOKEN="$TOKEN" sh

# Wait for K3s to be ready
echo "Waiting for K3s agent to be ready..."
sleep 10

echo "K3s agent node registration complete!"
echo "Check status on master with: kubectl get nodes"