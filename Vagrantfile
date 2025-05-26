# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.box_check_update = false

  # Define k3s master node
  config.vm.define "master" do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "192.168.56.10"

    # Forward port for API server
    master.vm.network "forwarded_port", guest: 6443, host: 6443
    # Forward port for NodePort services
    master.vm.network "forwarded_port", guest: 30000, host: 30000

    master.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
      vb.name = "k3s-master"
    end

    # Install k3s server
    master.vm.provision "shell", path: "./Scripts/k3s-master.sh"

    # Copy kubeconfig file to host
    master.vm.provision "shell", privileged: true, inline: <<-SHELL
      mkdir -p /vagrant/.kube
      cp /etc/rancher/k3s/k3s.yaml /vagrant/.kube/config
      sed -i 's/127.0.0.1/192.168.56.10/g' /vagrant/.kube/config
      chmod 644 /vagrant/.kube/config
    SHELL
  end

  # Define k3s agent node
  config.vm.define "agent" do |agent|
    agent.vm.hostname = "agent"
    agent.vm.network "private_network", ip: "192.168.56.11"

    agent.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
      vb.name = "k3s-agent"
    end

    # Install k3s agent
    agent.vm.provision "shell", path: "./Scripts/k3s-worker.sh"
  end
end
