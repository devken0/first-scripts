#!/usr/bin/env bash

# Adding new user to the system
echo "Creating standard user..."
read -p "Enter preferred username: " USERNAME
adduser "$USERNAME"

# Update package lists and upgrade installed packages
echo "Updating package lists and upgrading installed packages..."
apt update && apt upgrade -y

# Installing essential packages
echo "Installing essential packages..."
apt install sudo wget curl git -y  

# Configure system settings
echo "Configuring system settings..."

timedatectl set-timezone Asia/Manila
echo "Changed timeone"

usermod -aG sudo $USERNAME
newgrp sudo
echo "Added user to sudo group" 

mkdir /home/$USERNAME/.ssh
sed -i -E 's/^(#)?PermitRootLogin (prohibit-password|yes)/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i -E 's/^(#)?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh
echo "Secured ssh access"

# Additional configurations...
# Install Docker Engine

# clean install preparation 
echo "Docker install preparation..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
# Install Docker packages
echo "Installing docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
# Set permissions
sudo usermod -aG docker $USERNAME
newgrp docker

# Clone compose repository
echo "Cloning docker compose repository..."
git clone https://github.com/devken0/docker-homelab.git
git config --global user.name "$USERNAME"
git config --global user.email "homelab.ken@gmail.com"

echo "Post-installation tasks completed. Please relogin or reboot."
