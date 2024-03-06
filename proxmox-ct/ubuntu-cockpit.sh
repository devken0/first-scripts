#!/usr/bin/env bash

internal_ip=$(hostname -I)
cockpit_port=9090

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
echo "SSH auth disabled for root, enabled for $username."

# Additional configurations...
# Install Cockpit
apt install cockpit
systemctl enable cockpit --now

# Install Cockpit Applications
curl -sSL https://repo.45drives.com/setup -o setup-repo.sh
bash setup-repo.sh
apt-get update
apt install cockpit-navigator cockpit-identities cockpit-file-sharing

echo "Cockpit Web Interface is available at https://$internal_ip:$cockpit_port. Please relogin or reboot.."
