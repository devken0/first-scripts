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
ssh-keygen -t ed25519
cat ~/.ssh/id_ed25519.pub
read -rns1 -p "Please copy generated ssh-key to github.";echo
sudo ufw allow 14/tcp,10000/tcp
sudo ufw allow OpenSSH
sudo sed -i -E 's/^(#)?Port 22/Port 14/' /etc/ssh/sshd_config
sudo sed -i -E 's/^(#)?PermitRootLogin (prohibit-password|yes)/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i -E 's/^(#)?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
echo "Secured ssh access"
echo "SSH auth disabled for root, enabled for $USER."
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

echo "Installing docker..."
# clean install preparation 
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# preview
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh --dry-run

# final
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

sudo usermod -aG docker $USER

curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

git config --global user.name "ken"
git config --global user.email "ken@minihomebox.lan"
git clone https://github.com/devken0/docker-homelab.git
cd ~/docker-homelab
docker compose up -d

echo "Configuring system settings..."
sudo timedatectl set-timezone Asia/Manila
echo "Changed timeone"
sudo cp /etc/sysctl.conf /etc/sysctl.conf.bak
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

# Define the new hostname and domain
new_hostname="minihomebox.duckdns.org"
new_alias="minihomebox"
ip_address="127.0.1.1"

# Remove existing entry for 127.0.1.1 in /etc/hosts
sudo sed -i "/^$ip_address/d" /etc/hosts

# Add the new entry to /etc/hosts
echo "$ip_address $new_hostname $new_alias" | sudo tee -a /etc/hosts >/dev/null

echo "Entry for $ip_address updated with $new_hostname $new_alias"

# Define the new hostname
new_hostname="minihomebox.duckdns.org"

# Change hostname in /etc/hostname
echo "$new_hostname" | sudo tee /etc/hostname >/dev/null

# Update the current hostname
sudo hostnamectl set-hostname "$new_hostname"

echo "Hostname changed to $new_hostname"

# modify cockpit.conf for nginx
echo '[WebService]
AllowUnencrypted = True
Origins=http://admin.minihomebox.lan http://admin.minihomebox.duckdns.org http://minihomebox.duckdns.org:9090 ' | sudo tee -a /etc/cockpit/cockpit.conf 

# Define the interface and configuration file
INTERFACE="enp1s0"  # Replace with your interface name
CONFIG_FILE="/etc/netplan/00-installer-config.yaml"  # Replace with your Netplan configuration file

# Check if the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Netplan configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Check if the interface is already configured for Wake-on-LAN
if grep -q "wakeonlan: true" "$CONFIG_FILE"; then
    echo "Wake-on-LAN is already enabled for interface: $INTERFACE"
    exit 0
fi

# Add wakeonlan: true under the specified interface
sudo sed -i "/$INTERFACE:/a \ \ \ \ wakeonlan: true" "$CONFIG_FILE"

# Apply the Netplan configuration
sudo netplan apply

echo "Wake-on-LAN enabled for interface: $INTERFACE"

sudo cp /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.bak
echo "  renderer: NetworkManager" | sudo tee -a /etc/netplan/00-installer-config.yaml >/dev/null
sudo netplan try
sudo netplan apply

touch ~/.bash_aliases
echo "alias lzd='lazydocker'" >> ~/.bash_aliases
cat << "EOF" >> ~/.bash_aliases
# Docker aliases
alias dps='docker ps'                      # List running containers
alias dpsa='docker ps -a'                  # List all containers (including stopped)
alias dimages='docker images'              # List Docker images
alias drmi='docker rmi'                    # Remove Docker image
alias drmia='docker rmi $(docker images -q)' # Remove all Docker images
alias dvolume='docker volume'              # Manage Docker volumes
alias dlogs='docker logs'                  # View logs of a Docker container
alias dstop='docker stop'                  # Stop a Docker container
alias dstart='docker start'                # Start a stopped Docker container
alias dexec='docker exec -it'              # Execute a command inside a Docker container
alias dclean='docker system prune -a'      # Clean up Docker resources
alias dinfo='docker info'                  # Display Docker system-wide information
alias lzd='lazydocker'                     # lazydocker

# Docker Compose aliases
alias dc='docker-compose'                         # Shortcut for docker-compose
alias dcu='docker-compose up'                     # Start Docker Compose services
alias dcd='docker-compose down'                   # Stop Docker Compose services
alias dcl='docker-compose logs'                   # View logs of Docker Compose services
alias dcps='docker-compose ps'                    # List Docker Compose services
alias dcr='docker-compose run --rm'               # Run a one-off command in a Docker Compose service
alias dcstop='docker-compose stop'                # Stop Docker Compose services
alias dcrestart='docker-compose restart'          # Restart Docker Compose services
alias dcbuild='docker-compose build'              # Build Docker Compose services
alias dcexec='docker-compose exec'                # Execute a command in a running Docker Compose service
alias dcdown='docker-compose down --volumes'      # Stop and remove Docker Compose services along with volumes
alias dcupb='docker-compose up --build'           # Start Docker Compose services and rebuild images
alias dclogs='docker-compose logs -f'             # View real-time logs of Docker Compose services
EOF
source ~/.bash_aliases

echo "Cockpit Web Interface is now running at https://$internal_ip:9090. Please relogin or reboot.."
echo -n "SSH is now running at port 14."
for i in {1..5}; do
    echo -n "."
    sleep 1
done
sudo ufw delete allow OpenSSH
sudo systemctl restart ssh
echo " Done!"
