#!/usr/bin/env bash

internal_ip=$(hostname -I)

# Adding new user to the system
echo "Creating standard user..."
read -p "Enter preferred username: " username
adduser "$username"

# Update package lists and upgrade installed packages
echo "Updating package lists and upgrading installed packages..."
apt update && apt upgrade -y

# Installing essential packages
echo "Installing essential packages..."
apt install sudo wget curl neovim git rsync -y  

# Configure system settings
echo "Configuring system settings..."

timedatectl set-timezone Asia/Manila
echo "Changed timeone"

usermod -aG sudo $username
echo "Granted root privileges to $username" 

echo "Type new password for root"
passwd
rsync --archive --chown=$username:$username ~/.ssh /home/$username
sed -i -E 's/^(#)?PermitRootLogin (prohibit-password|yes)/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i -E 's/^(#)?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh
echo "Secured ssh access"
echo "SSH auth disabled for root, enabled for $USERNAME."

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
sudo usermod -aG docker $username

# Clone compose repository
echo "Cloning docker compose repository..."
cd /home/$username/
git clone https://github.com/devken0/docker-homelab.git
chown -R $username:$username docker-homelab
git config --global user.name "$username"
git config --global user.email "homelab.ken@gmail.com"

# Add cron job to crontab
su $USERNAME
cd /home/$USERNAME/docker-homelab
crontab -l > existing-crontab
cat crontab >> existing-crontab
crontab existing-crontab
rm existing-crontab
echo "Cron jobs added successfully."

exit

echo "Post-installation tasks completed. Please relogin or reboot."
