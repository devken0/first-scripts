#!/usr/bin/env bash

internal_ip=$(hostname -I)
# Initial setup
setup-alpine

# Adding new user to the system
echo "Creating standard user..."
read -p "Enter preferred username: " username
adduser "$username"

# Update package lists and upgrade installed packages
echo "Updating package lists and upgrading installed packages..."
apk update
apk upgrade

# Installing docker and docker compose
echo "Installing docker..."
apk add docker docker-compose

# Start and enable Docker
echo "Docker enabled at startup."
rc-update add docker boot
service docker start
docker --version
docker info

# Add user to docker group
echo "Added user to docker group."
adduser $username docker

# Securing the system
echo "Installing sudo..."
apk add sudo
addgroup $username wheel
echo "Granted root privileges to $username" 
echo "Type new password for root"
passwd
echo "Installing ssh..."
apk add openssh
rc-update add sshd
rc-service sshd start
echo "Securing ssh..."
# Prompt the user for input
echo "Please enter the SSH public key:"
read ssh_key

# Check if ~/.ssh/authorized_keys exists, if not, create it
authorized_keys_file="home/$username/.ssh/authorized_keys"
if [ ! -f "$authorized_keys_file" ]; then
    touch "$authorized_keys_file"
    chmod 600 "$authorized_keys_file"
fi

# Append the SSH public key to the authorized_keys file
echo "$ssh_key" >> "$authorized_keys_file"

echo "SSH public key added to /home/$username/.ssh/authorized_keys."

sed -i -E 's/^(#)?PermitRootLogin (prohibit-password|yes)/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i -E 's/^(#)?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
rc-service sshd restart

echo "SSH auth disabled for root, enabled for $username."

#echo "Installing fail2ban..."
#apk add fail2ban
#rc-update add fail2ban
#service fail2ban start
#echo "Installing ufw..."
#apk add ufw
#rc-update add ufw
#rc-service ufw start
#ufw allow ssh
#ufw enable

# Enable automatic security updates
echo "Enabling automatic security updates..."
apk add apk-cron
rc-update add apk-cron
rc-service apk-cron start

echo "Post-installation tasks completed. Please relogin or reboot."
