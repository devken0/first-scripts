#!/usr/bin/env bash

internal_ip=$(hostname -I)

echo "Updating package lists and upgrading installed packages..."
sudo apt-get update && sudo apt-get upgrade -y

#echo "Enabling automatic upgrades..."
#sudo apt-get install unattended-upgrades update-notifier-common
#sudo dpkg-reconfigure --priority=low unattended-upgrades
#sudo unattended-upgrade --dry-run --debug

echo "Installing essential packages..."
sudo apt install sudo wget curl neovim git dnsutils rsync ncdu apt-transport-https ca-certificates software-properties-common lm-sensors net-tools htop iotop glances rclone -y  

echo "Securing the system..."
sudo ufw allow 14/tcp,10000/tcp
sudo ufw allow OpenSSH
sudo sed -i -E 's/^(#)?Port 22/Port 14/' /etc/ssh/sshd_config
sudo sed -i -E 's/^(#)?PermitRootLogin (prohibit-password|yes)/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i -E 's/^(#)?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
echo "Secured ssh access"
echo "SSH auth disabled for root, enabled for $USER."
sudo ufw delete allow OpenSSH
sudo ufw reload
sudo ufw enable
sudo apt-get install fail2ban
sudo systemctl enable fail2ban --now
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nvim /etc/fail2ban/jail.local
sudo systemctl restart fail2ban
sudo fail2ban-client status

sudo apt-get install cockpit 
sudo systemctl enable cockpit --now

curl -sSL https://repo.45drives.com/setup -o setup-repo.sh
bash setup-repo.sh
apt-get update
apt install cockpit-navigator cockpit-identities cockpit-file-sharing cockpit-machines -y

curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh
sh setup-repos.sh
sudo apt-get install webmin --install-recommends

echo "Configuring system settings..."
sudo timedatectl set-timezone Asia/Manila
echo "Changed timeone"
sudo cp /etc/sysctl.conf /etc/sysctl.conf.backup
sudo cat << "EOF" >> /etc/sysctl.conf
# Set swappiness value
vm.swappiness=10

# Set maximum percentage of system memory for dirty pages
vm.dirty_ratio=20
vm.dirty_background_ratio=10

# Adjust network parameters
net.core.somaxconn=65535
net.core.netdev_max_backlog=65536
net.core.rmem_max=67108864
net.core.wmem_max=67108864

# Security settings
kernel.core_pattern=core
kernel.randomize_va_space=2
EOF
sudo sysctl -p
echo "Configured sysctl.conf"

echo "Cockpit Web Interface is now running at https://$internal_ip:9090. Please relogin or reboot.."
echo -n "SSH is now running at port 14."
for i in {1..5}; do
    echo -n "."
    sleep 1
done
sudo systemctl restart ssh
echo " Done!"
