#!/usr/bin/env bash

# Global variables 

internal_ip=$(hostname -I)
INTERFACE=$(ip route get 8.8.8.8 | awk '{print $5}' | tr -d '\n')
CONFIG_FILE="/etc/netplan/00-installer-config.yaml" 

# Functions

getting_variables(){
    read -p "Preferred custom ssh port: " ssh_port
    read -p "Preferred hostname: " new_hostname 
    read -p "Preferred hostname alias: " new_alias
    read -p "Please type in preferred origin urls for cockpit (separated by spaces): " origins
    read -p "Please enter ssh repository url for cloning docker compose files: " compose_repo
}

update_system(){
    echo "Updating package lists and upgrading installed packages..."
    sudo apt-get update && sudo apt-get upgrade -y || { echo "Failed to update packages"; exit 1; }
}

#enabling_automatic_updates(){
    #echo "Enabling automatic upgrades..."
    #sudo apt-get install unattended-upgrades update-notifier-common
    #sudo dpkg-reconfigure --priority=low unattended-upgrades
    #sudo unattended-upgrade --dry-run --debug
#}

install_essential_packages(){
    echo "Installing essential packages..."
    sudo apt-get install wget tasksel curl neovim git dnsutils rsync ncdu apt-transport-https ca-certificates software-properties-common lm-sensors net-tools htop iotop glances rclone -y || { echo "Failed to install essential packages"; exit 1; } 
    . /etc/os-release
    sudo apt-get install -t ${VERSION_CODENAME}-backports cockpit -y || { echo "Failed to install cockpit"; exit 1; } 
    sudo systemctl enable cockpit --now || { echo "Failed to enable cockpit"; exit 1; }

    curl -sSL https://repo.45drives.com/setup -o setup-repo.sh
    bash setup-repo.sh
    sudo apt-get update
    sudo apt install cockpit-navigator cockpit-identities cockpit-file-sharing cockpit-machines -y || { echo "Failed to install cockpit apps"; exit 1; } 

    curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh
    sh setup-repos.sh
    sudo apt-get install webmin --install-recommends -y || { echo "Failed to install webmin"; exit 1; }
    sudo tasksel
    # Add prompt to user if would like to add any more packages
}

secure_system() {
    echo "Securing the system..."
    # Adding ssh key to github
    ssh-keygen -t ed25519 || { echo "Failed to generate SSH key"; exit 1; }
    cat ~/.ssh/id_ed25519.pub
    read -rns1 -p "Please copy the generated SSH key to GitHub, then press any key to continue."; echo ""
    # Configuring firewall 
    sudo ufw allow $ssh_port/tcp,10000/tcp,9090/tcp || { echo "Failed to add firewall rules"; exit 1; }
    # Configuring ssh
    sudo sed -i -E "s/^(#)?Port 22/Port $ssh_port/" /etc/ssh/sshd_config
    sudo sed -i -E 's/^(#)?PermitRootLogin (prohibit-password|yes)/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i -E 's/^(#)?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    echo "Secured ssh access"
    echo "SSH auth disabled for root, enabled for $USER."
    # Configuring fail2ban
    sudo apt-get install fail2ban -y || { echo "Failed to install fail2ban"; exit 1; }
    sudo systemctl enable fail2ban --now || { echo "Failed to enable fail2ban"; exit 1; }
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    read -rns1 -p "Local jails configuration for fail2ban will be opened, press any key to continue."; echo ""
    sudo nvim /etc/fail2ban/jail.local
    sudo systemctl restart fail2ban || { echo "Failed to restart fail2ban"; exit 1; }
    sudo fail2ban-client status
}

install_docker() {
    echo "Installing docker..."
    # Docker installation commands
    # Install preparation 
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
    sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
    # Preview mode
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh ./get-docker.sh --dry-run
    # Final
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh || { echo "Failed to docker"; exit 1; }
    # Setting permissions
    sudo usermod -aG docker $USER
    # Docker TUI
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash || { echo "Failed to install lazydocker"; exit 1; }
    # Setting up git
    cd ~
    git config --global user.name "ken"
    git config --global user.email "ken@minihomebox.lan"
    git clone $compose_repo || { echo "Failed to clone repository"; exit 1; }
    cd ~/docker-homelab
    docker compose up -d || { echo "Failed to start docker containers"; exit 1; }
}

configure_system_settings() {
    echo "Configuring system settings..."
    # System configuration commands
    sudo timedatectl set-timezone Asia/Manila || { echo "Failed to set correct timezone"; exit 1; }
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
    sudo sysctl -p || { echo "Failed to configure sysctl.conf"; exit 1; }
    echo "Configured sysctl.conf"
    # Remove existing entry for 127.0.1.1 in /etc/hosts
    sudo sed -i "/^127.0.1.1/d" /etc/hosts
    
    # Add the new entry to /etc/hosts
    echo "127.0.1.1 $new_hostname $new_alias" | sudo tee -a /etc/hosts >/dev/null
    
    echo "Entry for 127.0.1.1 updated with $new_hostname $new_alias"
    # Change hostname in /etc/hostname
    echo "$new_hostname" | sudo tee /etc/hostname >/dev/null
    
    # Update the current hostname
    sudo hostnamectl set-hostname "$new_hostname"
    
    echo "Hostname changed to $new_hostname"
    # Modify cockpit.conf for nginx
    echo "[WebService]
    AllowUnencrypted = True
    Origins=$(echo $origins | tr ' ' '\n')" | sudo tee -a /etc/cockpit/cockpit.conf 

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
    sudo netplan apply || { echo "Failed to apply netplan changes"; exit 1; }

    echo "Wake-on-LAN enabled for interface: $INTERFACE"

    # Changing netplan renderer
    sudo cp /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.bak
    echo "  renderer: NetworkManager" | sudo tee -a /etc/netplan/00-installer-config.yaml >/dev/null
    sudo netplan try
    sudo netplan apply || { echo "Failed to apply netplan changes"; exit 1; }
}

set_bash_aliases() {
   touch ~/.bash_aliases
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
}

# Main script

main() {
    if [[ $EUID -ne 0 ]]; then
       echo -e "\e[31mThis script must be run as root\e[0m" 
       exit 1
    fi
    update_system
    echo -e "\e[32mDone updating system.\e[0m"
    install_essential_packages
    echo -e "\e[32mDone installation of packages.\e[0m"
    secure_system
    echo -e "\e[32mDone securing system.\e[0m"
    install_docker
    echo -e "\e[32mDone installing docker.\e[0m"
    configure_system_settings
    echo -e "\e[32mDone configuring system.\e[0m"
    set_bash_aliases
    echo -e "\e[32mDone saving bash aliases.\e[0m"
    # Additional tasks...
    echo "Before you go..."
    for i in {1..5}; do
        echo -n "."
        sleep 1
    done
    sudo ufw delete allow OpenSSH 
    sudo ufw delete allow 22/tcp 
    sudo ufw reload
    sudo ufw enable || { echo "Failed to configure firewall"; exit 1; }
    echo "Cockpit can be accessed at http://$internal_ip:9090"
    echo -n "SSH is now running at port 14."
    echo -e "\e[34mTasks complete, please relogin or reboot.\e[0m"
}

main "$@"
