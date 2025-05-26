#!/bin/bash

# Update and install dependencies
apt-get update
apt-get install -y curl

# Set master IP address (using the private network interface)
masterIP="192.168.56.10"

# Install K3s as a server (master) with proper network configuration
export INSTALL_K3S_EXEC="--bind-address=${masterIP} --advertise-address=${masterIP} --flannel-iface=enp0s8 --node-ip=${masterIP} --write-kubeconfig-mode=644 --node-name=master --cluster-init"
curl -sfL https://get.k3s.io | sh

# Get the token and save it for the worker node
echo "Saving K3s token to /vagrant/token..."
cat /var/lib/rancher/k3s/server/node-token > /vagrant/token

# Wait for K3s to be ready
echo "Waiting for K3s to be ready..."
sleep 10
until kubectl get nodes | grep master | grep -q " Ready"; do
  sleep 5
  echo "Still waiting for K3s to be ready..."
done

echo "K3s master node is ready!"