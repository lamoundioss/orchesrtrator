#!/bin/bash

# Define colors for terminal output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if Vagrant is installed
check_requirements() {
    if ! command -v vagrant &> /dev/null; then
        echo -e "${RED}Error: Vagrant is not installed. Please install Vagrant first.${NC}"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}Warning: kubectl is not installed. You'll need it to interact with the cluster.${NC}"
    fi
}

# Function to create the cluster
create_cluster() {
    echo "Creating K3s cluster..."
    vagrant up
    
    # Wait for the cluster to be ready
    sleep 10
    
    # Configure kubectl to use the cluster
    if [ -f .kube/config ]; then
        export KUBECONFIG="$(pwd)/.kube/config"
        
        # Configure kubectl to skip TLS verification
        echo "Configuring kubectl to skip TLS verification..."
        kubectl config set-cluster default --insecure-skip-tls-verify=true
        
        # Apply Kubernetes manifests
        if [ -d "Manifests" ]; then
            echo "Applying Kubernetes manifests..."
            cd Manifests
            ./apply-manifest.sh
            cd ..
        else
            echo -e "${RED}Manifests directory not found!${NC}"
        fi
        
        # Verify the connection
        echo "Verifying connection to the Kubernetes cluster..."
        if kubectl get nodes &> /dev/null; then
            export KUBECONFIG="$(pwd)/.kube/config"
            echo -e "${GREEN}Cluster created successfully and kubectl is configured!${NC}"
        else
            echo -e "${RED}Cluster created but kubectl connection failed. Check your network configuration.${NC}"
        fi
    else
        echo -e "${RED}Failed to find kubeconfig file. Cluster may not be ready.${NC}"
        exit 1
    fi
}

# Function to start the cluster
start_cluster() {
    echo "Starting K3s cluster..."
    vagrant up
    echo -e "${GREEN}Cluster started${NC}"
}

# Function to stop the cluster
stop_cluster() {
    echo "Stopping K3s cluster..."
    vagrant halt
    echo -e "${GREEN}Cluster stopped${NC}"
}

# Function to destroy the cluster
destroy_cluster() {
    echo "Destroying K3s cluster..."
    vagrant destroy -f
    echo -e "${GREEN}Cluster destroyed${NC}"
}

# Function to show cluster status
status_cluster() {
    if vagrant status | grep -q "running"; then
        echo -e "${GREEN}Cluster is running${NC}"
        if [ -f .kube/config ]; then
            export KUBECONFIG="$(pwd)/.kube/config"
            # Ensure TLS verification is skipped for status command
            kubectl config set-cluster default --insecure-skip-tls-verify=true &> /dev/null
            echo "Nodes in the cluster:"
            kubectl get nodes -o wide
        else
            echo -e "${RED}Unable to get cluster status: kubeconfig not found${NC}"
        fi
    else
        echo -e "${RED}Cluster is not running${NC}"
    fi
}

# Function to install Kubernetes Dashboard
install_dashboard() {
    if vagrant status | grep -q "running"; then
        echo -e "${GREEN}Installing Kubernetes Dashboard...${NC}"
        if [ -f install-dashboard.sh ]; then
            ./install-dashboard.sh
        else
            echo -e "${RED}Dashboard installation script not found!${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Cluster is not running. Start it first with: ./orchestrator.sh start${NC}"
        exit 1
    fi
}

# Function to install Log Dashboard
install_logs() {
    if vagrant status | grep -q "running"; then
        echo -e "${GREEN}Installing Log Dashboard (Grafana + Loki)...${NC}"
        if [ -f install-log-dashboard.sh ]; then
            ./install-log-dashboard.sh
        else
            echo -e "${RED}Log dashboard installation script not found!${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Cluster is not running. Start it first with: ./orchestrator.sh start${NC}"
        exit 1
    fi
}

# Check requirements
check_requirements

# Process command line arguments
case "$1" in
    create)
        create_cluster
        ;;
    start)
        start_cluster
        ;;
    stop)
        stop_cluster
        ;;
    destroy)
        destroy_cluster
        ;;
    status)
        status_cluster
        ;;
    dashboard)
        install_dashboard
        ;;
    logs)
        install_logs
        ;;
    *)
        echo "Usage: $0 {create|start|stop|destroy|status|dashboard|logs}"
        exit 1
        ;;
esac

exit 0