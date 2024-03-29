#!/usr/bin/env bash

# Global variables 

internal_ip=$(hostname -I)
INTERFACE=$(ip route get 8.8.8.8 | awk '{print $5}' | tr -d '\n')
CONFIG_FILE="/etc/netplan/00-installer-config.yaml" 

# Functions

get_variables(){
    read -p "Type your standard username (non-root): " username
    read -p "Preferred custom ssh port: " ssh_port
    read -p "Preffered nextcloud http port (80): " nextcloud_http_port
    read -p "Preffered nextcloud https port (443): " nextcloud_https_port
    read -p "Your nextcloud domain name: " nextcloud_domain_name
    read -p "Your reverse proxy's ip: " proxy_ip 
    read -p "Preferred hostname: " new_hostname 
    read -p "Preferred hostname alias: " new_alias
    read -p "Please type in preferred origin urls for cockpit (separated by spaces, https only): " origins
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
    wget https://github.com/ocristopfer/cockpit-sensors/releases/latest/download/cockpit-sensors.tar.xz && \
  tar -xf cockpit-sensors.tar.xz cockpit-sensors/dist && \
  mv cockpit-sensors/dist /usr/share/cockpit/sensors && \
  rm -r cockpit-sensors && \
  rm cockpit-sensors.tar.xz || { echo "Failed to install cockpit-sensors"; exit 1; }

    curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh
    sh setup-repos.sh
    sudo apt-get install webmin --install-recommends -y || { echo "Failed to install webmin"; exit 1; }
    sudo tasksel
    # Add prompt to user if would like to add any more packages
}
nextcloud_snap_setup(){
    sudo apt install snapd
    sudo snap install nextcloud
    sudo ufw allow $nextcloud_http_port/tcp
    sudo ufw allow $nextcloud_https_port/tcp
    sudo snap connect nextcloud:removable-media
    sudo snap set nextcloud ports.http=$nextcloud_http_port ports.https=$nextcloud_https_port
    #sudo snap connect nextcloud:network-observe
    # overwrite parameters
    #sudo nextcloud.occ config:system:set overwritehost --value="example.com:81"
    #sudo nextcloud.occ config:system:set overwriteprotocol --value="https"
    sudo nvim /var/snap/nextcloud/current/nextcloud/config/config.php
    sudo snap set nextcloud php.memory-limit=512M
    sudo snap set nextcloud http.compression=true
    sudo nextcloud.disable-https lets-encrypt
    sudo snap stop --disable nextcloud.renew-certs
    # run this commands after the initial setup of nextcloud
    #sudo nextcloud.occ config:system:set trusted_proxies 0 --value="$proxy_ip"
    #sudo nextcloud.occ config:system:set trusted_domains 1 --value="$nextcloud_domain_name"
    #sudo snap set nextcloud mode=debug
    #sudo snap set nextcloud http.notify-push-reverse-proxy=true
    #sudo snap set nextcloud nextcloud.cron-interval=10m
    #sudo nextcloud.enable-https lets-encrypt
    # backup except data
    #sudo rm -rf /var/snap/nextcloud/common/nextcloud/backups
    #sudo mkdir /mnt/slow_2tb/nc-backups
    #sudo ln -s /mnt/slow_2tb/nc-backups /var/snap/nextcloud/common/nextcloud/backups
    #sudo nextcloud.export -abc
    # restoration
    #sudo rm -rf /var/snap/nextcloud/common/nextcloud/backups
    #sudo ln -s /mnt/slow_2tb/nc-backups /var/snap/nextcloud/common/nextcloud/backups
    #sudo nextcloud.import -abc /var/snap/nextcloud/common/nextcloud/backups/file_name
    # create snapshots

    # backup script
#cat <<EOF > $HOME/bin/nextcloud_snapshot.sh
##!/usr/bin/env bash
###############################################################
### Nextcloud snap backup with Snap snapshots -- SCUBA --
### -scubamuc- https://scubamuc.github.io/ 
###############################################################
### create target directory "sudo mkdir /mnt/nc-snaps"
### snapshot rotation 30 days 
### create crontab as root for automation
### 0 1 * * 0 su $USER /home/$USER/bin/nextcloud_snapshot.sh
###############################################################
## VARIABLES #
###############################################################
#
#SNAPNAME="nextcloud"
#TARGET="/media/SNAPBACKUP"  ## target directory
#LOG="/media/SNAPBACKUP/snapbackup-nc.log"  ## logfile
#SOURCE="/var/lib/snapd/snapshots" ## source directory
#RETENTION="30" ## retention in days
#
###############################################################
## FUNCTIONS #
###############################################################
#
### Timestamp for Log ##
#timestamp()
#{
# date +"%Y-%m-%d %T"
#}
#
###############################################################
## SCRIPT #
###############################################################
#
### start log  
#echo "********************************************************" >> "$LOG" ; ## log seperator
#echo "$(timestamp) -- Snapbackup $SNAPNAME Start" >> "$LOG" ; ## start log
#
### stop snap for snapshot  
# sudo snap stop "$SNAPNAME" ;
### create snap snapshot 
# sudo snap save --abs-time "$SNAPNAME" ;
### restart snap after snapshot 
# sudo snap start "$SNAPNAME" ;
#
### find and move snapshot to $TARGET  
# sudo find "$SOURCE"/ -name "*.zip" -exec mv '{}' "$TARGET"/ \; # find and move
### find old snapshots and delete snapshots older than $RETENTION days
# sudo find "$TARGET"/ -name "*.zip" -mtime +"$RETENTION" -exec rm -f {} \; # find and delete
#
### end log 
# echo "$(timestamp) -- Snapbackup "$SNAPNAME" End " >> "$LOG" ; ## end log 
# echo "" >> "$LOG" ;  ## log linefeed 
#
#exit
#EOF
#(crontab -l ; echo "0 1 * * 0 su $USER /home/$USER/bin/nextcloud_snapshot.sh") | crontab -
}

#rclone_setup(){
#}
#idrive_setup(){
#}

secure_system() {
    echo "Securing the system..."
    # Adding ssh key to github
    sudo -u $username ssh-keygen -t ed25519 || { echo "Failed to generate SSH key"; exit 1; }
    cat ~/.ssh/id_ed25519.pub
    read -rn1 -p "Please copy the generated SSH key to GitHub, then press any key to continue."; echo ""
    # Configuring firewall 
    sudo ufw allow "$ssh_port/tcp" || { echo "Failed to add firewall rules"; exit 1; }
    sudo ufw allow 9090/tcp || { echo "Failed to add firewall rules"; exit 1; }
    sudo ufw allow 10000/tcp || { echo "Failed to add firewall rules"; exit 1; }
    # Configuring ssh
    sudo sed -i -E "s/^(#)?Port 22/Port $ssh_port/" /etc/ssh/sshd_config
    sudo sed -i -E 's/^(#)?PermitRootLogin (prohibit-password|yes)/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i -E 's/^(#)?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    echo "Secured ssh access"
    echo "SSH auth disabled for root, enabled for $username."
    # Configuring fail2ban
    sudo apt-get install fail2ban -y || { echo "Failed to install fail2ban"; exit 1; }
    sudo systemctl enable fail2ban --now || { echo "Failed to enable fail2ban"; exit 1; }
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    read -rn1 -p "Local jails configuration for fail2ban will be opened, press any key to continue."; echo ""
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
    sudo usermod -aG docker $username
    # Docker TUI
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash || { echo "Failed to install lazydocker"; exit 1; }
    # Preparing for container stack
    # Pihole
    sudo systemctl disable systemd-resolved
    sudo systemctl stop systemd-resolved
    touch ~/.bashrc
    echo "export PATH="/$HOME/.local/bin:$PATH"" | tee -a ~/.bashrc
    # Setting up git
    cd ~
    git config --global user.name "ken"
    git config --global user.email "ken@minihomebox.lan"
    git clone $compose_repo || { echo "Failed to clone repository"; exit 1; }
    cd ~/docker-homelab
    docker compose up -d || { echo "Failed to start docker containers"; exit 1; }
}

#setup_github_backup(){
#}

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
    
    # Add wakeonlan: true under the specified interface
    # Add wakeonlan: true under the specified interface
    sudo sed -i "/$INTERFACE:/a \ \ \ \   wakeonlan: true" "$CONFIG_FILE"
    
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
alias dc='docker compose'                         # Shortcut for docker-compose
alias dcu='docker compose up'                     # Start Docker Compose services
alias dcd='docker compose down'                   # Stop Docker Compose services
alias dcl='docker compose logs'                   # View logs of Docker Compose services
alias dcps='docker compose ps'                    # List Docker Compose services
alias dcr='docker compose run --rm'               # Run a one-off command in a Docker Compose service
alias dcstop='docker compose stop'                # Stop Docker Compose services
alias dcrestart='docker compose restart'          # Restart Docker Compose services
alias dcbuild='docker compose build'              # Build Docker Compose services
alias dcexec='docker compose exec'                # Execute a command in a running Docker Compose service
alias dcdown='docker compose down --volumes'      # Stop and remove Docker Compose services along with volumes
alias dcupb='docker compose up --build'           # Start Docker Compose services and rebuild images
alias dclogs='docker compose logs -f'             # View real-time logs of Docker Compose services
EOF
    source ~/.bash_aliases
}

# Main script

main() {
    #if [[ $EUID -ne 0 ]]; then
    #   echo "$(tput setaf 1)This script must be run as root.$(tput sgr0)" 
    #   exit 1
    #fi
    get_variables
    echo "$(tput setaf 2)Done getting user info.$(tput sgr0)"
    update_system
    echo "$(tput setaf 2)Done updating system.$(tput sgr0)"
    install_essential_packages
    echo "$(tput setaf 2)Done installation of packages.$(tput sgr0)"
    nextcloud_snap_setup
    echo "$(tput setaf 2)Done setting up nextcloud.$(tput sgr0)"
    #rclone_setup
    #echo "$(tput setaf 2)Done setting up rclone.$(tput sgr0)"
    #idrive_setup
    #echo "$(tput setaf 2)Done setting up idrive.$(tput sgr0)"
    secure_system
    echo "$(tput setaf 2)Done securing system.$(tput sgr0)"
    #pivpn_setup
    #echo "$(tput setaf 2)Done setting up pivpn.$(tput sgr0)"
    install_docker
    echo "$(tput setaf 2)Done installing docker.$(tput sgr0)"
    # setup paperless-ngx
    sudo $ bash -c "$(curl --location --silent --show-error https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/main/install-paperless-ngx.sh)"
    #setup_github_backup
    #echo "$(tput setaf 2)Done setting up Github backups.$(tput sgr0)"
    configure_system_settings
    echo "$(tput setaf 2)Done configuring system.$(tput sgr0)"
    set_bash_aliases
    echo "$(tput setaf 2)Done saving bash aliases.$(tput sgr0)"
    # Additional tasks...
    echo -n "Before you go..."
    for i in {1..5}; do
        echo -n "."
        sleep 1
    done
    sudo ufw delete allow OpenSSH 
    sudo ufw delete allow 22/tcp 
    sudo ufw reload
    sudo ufw enable || { echo "Failed to configure firewall"; exit 1; }
    echo "$(tput setaf 6)Cockpit can be accessed at http://$internal_ip:9090$(tput sgr0)"
    echo "$(tput setaf 6)SSH is now running at port 14.$(tput sgr0)"
    echo "$(tput setaf 4)Tasks complete, please relogin or reboot.$(tput sgr0)"
}

main "$@"
