#!/usr/bin/env ash

internal_ip=$(hostname -i)
# Initial setup
setup-alpine

# Adding new user to the system
echo "Choosing username..."
read -p "Enter your username: " username

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
rc-service docker start
docker --version
docker info

# Add user to docker group
echo "Added user to docker group."
adduser $username docker

# Securing the system
echo "Installing sudo..."
apk add sudo
addgroup $username wheel
visudo
echo "Granted root privileges to $username" 

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
