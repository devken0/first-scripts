#!/usr/bin/env bash

# variables

APPDIR=/home/$USER/bin
# Initial updates

sudo dnf clean all 
sudo dnf update && sudo dnf upgrade
read -rns1 -p "Press any key to continue..";echo

sudo fwupdmgr refresh --force
sudo fwupdmgr get-updates
sudo fwupdmgr update
read -rns1 -p "Press any key to continue..";echo

# Install/setup system packages 

sudo dnf in https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel
sudo dnf install lame\* --exclude=lame-devel
sudo dnf group upgrade --with-optional Multimedia
sudo dnf in akmod-nvidia
sudo dnf in polkit-gnome
read -rns1 -p "Press any key to continue..";echo

# ----------------------------------

# required packages for the script

sudo dnf in wget

# security 

sudo dnf in ddclient
cat <<EOF | sudo tee /etc/ddclient.conf
##
## OpenDNS.com account-configuration
##
protocol=dyndns2
use=web, web=myip.dnsomatic.com
ssl=yes
server=updates.opendns.com
login=opendns_username
password='opendns_password'
opendns_network_label
EOF
sudo semanage fcontext -a -t ddclient_etc_t 'ddclient.conf'
sudo restorecon -v '/etc/ddclient.conf'
sudo systemctl enable ddclient --now
sudo dnf in https://repo.protonvpn.com/fedora-38-unstable/protonvpn-beta-release/protonvpn-beta-release-1.0.1-2.noarch.rpm
sudo dnf in protonvpn
wget -P ~/bin https://github.com/bitwarden/clients/releases/download/desktop-v2023.9.2/Bitwarden-2023.9.2-x86_64.AppImage
sudo ln -s ~/bin/Bitwarden-2023.9.2-x86_64.AppImage ~/.local/bin/bitwarden
sudo dnf in https://launchpad.net/veracrypt/trunk/1.26.7/+download/veracrypt-1.26.7-CentOS-8-x86_64.rpm
sudo dnf in keepassxc firewalld

# vms

# https://fedoramagazine.org/full-virtualization-system-on-fedora-workstation-30/
#sudo dnf in qemu @Virtualization
#sudo vi /etc/libvirt/libvirtd.conf
#sudo systemctl start libvirtd
#sudo systemctl enable libvirtd
#sudo usermod -a -G libvirt $(whoami)

# VMWare Workstation Player
# https://customerconnect.vmware.com/en/downloads/details?downloadGroup=WKST-PLAYER-1750&productId=1377&rPId=111473

# package manager

sudo dnf in dnfdragora 

# cleanup utils

sudo dnf in bleachbit

# Development  
# Setting up repositories
wget -P $HOME/Downloads https://dev.mysql.com/get/mysql80-community-release-fc39-1.noarch.rpm
cd $HOME/Downloads
sudo rpm -Uvh mysql80-community-release-*

# Install MySQL Workbench and Server
sudo dnf in mysql-workbench mysql

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat <<EOF | sudo tee /etc/yum.repos.d/vscode.repo
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
sudo dnf check-update
sudo dnf in code
sudo dnf in dotnet-sdk-7.0
sudo dnf in community-mysql-server
sudo dnf in https://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-workbench-community-8.0.34-1.fc38.x86_64.rpm
sudo sh -c 'echo -e "[unityhub]\nname=Unity Hub\nbaseurl=https://hub.unity3d.com/linux/repos/rpm/stable\nenabled=1\ngpgcheck=1\ngpgkey=https://hub.unity3d.com/linux/repos/rpm/stable/repodata/repomd.xml.key\nrepo_gpgcheck=1" > /etc/yum.repos.d/unityhub.repo'
sudo yum check-update
sudo yum in unityhub
sudo dnf in https://release.axocdn.com/linux/gitkraken-amd64.rpm
sudo dnf group in "C Development Tools and Libraries"
sudo dnf in cmake 
sudo dnf in android-tools
sudo dnf in npm

# productivity

#wget -P ~/bin https://electron-dl.todoist.net/linux/Todoist-linux-x86_64-8.9.1.AppImage
#cd ~/bin
#chmod +x *.AppImage
#ln -s ~/bin/Todoist-linux-x86_64-8.9.1.AppImage ~/.local/bin/todoist 

# downloaders

sudo dnf in qbittorrent uget 

# browsers

sudo dnf in dnf-plugins-core
sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
sudo dnf in brave-browser

# file sync utilities

sudo dnf in https://www.dropbox.com/download?dl=packages/fedora/nautilus-dropbox-2023.09.06-1.fedora.x86_64.rpm
dropbox start -i
sudo dnf in rclone syncthing

# file backup utilities

wget -P ~/bin https://www.idrivedownloads.com/downloads/linux/download-for-linux/LinuxScripts/IDriveForLinux.zip
cd ~/bin
unzip IDriveForLinux.zip
rm IDriveForLinux.zip

# system backup

sudo dnf in timeshift

# https://copr.fedorainfracloud.org/coprs/kylegospo/grub-btrfs/
#sudo dnf copr enable kylegospo/grub-btrfs  
#sudo dnf in grub-btrf-timeshift
#grub2-mkconfig -o /boot/grub2/grub.cfg
#sudo systemctl enable --now grub-btrfs.path 

# https://github.com/Antynea/grub-btrfs#-manual-usage-of-grub-btrfs
sudo dnf in inotify-tools btrfs-progs gawk
git clone https://github.com/Antynea/grub-btrfs.git
mv ~/grub-btrfs ~/bin/grub-btrfs 
sudo make install 
sudo systemctl enable --now grub-btrfsd
sudo systemctl edit --full grub-btrfsd
# replace ExecStart=/usr/bin/grub-btrfsd /.snapshots --syslog
# with ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto
sudo systemctl restart grub-btrfsd

# multimedia 

sudo dnf in --allowerasing mpv sxiv feh vlc picard peek kdenlive simplescreenrecorder flameshot ffmpeg ffmpeg-devel yt-dlp 

# communication

sudo dnf in kdeconnectd
sudo firewall-cmd --permanent --zone=public --add-service=kdeconnect
sudo firewall-cmd --reload

# office

sudo dnf in https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors.x86_64.rpm libreoffice apvlv 
wget -P ~/bin https://github.com/obsidianmd/obsidian-releases/releases/download/v1.4.16/Obsidian-1.4.16.AppImage
sudo ln -s ~/bin/Obsidian-1.4.16.AppImage ~/.local/bin/obsidian
sudo dnf in zathura

# cli utils 

sudo dnf in st speedtest-cli vim htop screenfetch ncdu ranger

# text editor
# https://www.sublimetext.com/docs/linux_repositories.html#dnf
sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
sudo dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
sudo dnf install sublime-text

# others

# ventoy

wget -P $APPDIR https://sourceforge.net/projects/ventoy/files/v1.0.96/ventoy-1.0.96-linux.tar.gz/download
ln -s $APPDIR/ventoy-*/VentoyGUI.x86_64 $HOME/.local/bin/ventoy

# waydroid

sudo dnf in waydroid

# universal android debloater

wget -P $APPDIR https://github.com/0x192/universal-android-debloater/releases/download/0.5.1/uad_gui-linux.tar.gz 

# devour - terminal window swallowing utility

cd $APPDIR
git clone https://github.com/salman-abedin/devour.sh.git


# gallery-dl (a youtube-dl clone) 
wget -P $APPDIR https://github.com/mikf/gallery-dl/releases/download/v1.26.2/gallery-dl.bin
cd $APPDIR
chmod +x gallery-dl.bin
ln -s $APPDIR/gallery-dl.bin /home/$USER/.local/bin/gallery-dl 

# packettracer
# Download from https://skillsforall.com/resources/lab-downloads
cd $APPDIR 
git clone https://github.com/thiagoojack/packettracer-fedora.git
cd $APPDIR/packettracer-fedora
chmod +x install.sh
./install.sh
sudo dnf copr enable skidnik/clipmenu
sudo dnf in screenkey xed vis vim-X11 xarchiver thunar-archive-plugin thunar-sendto-clamtk catfish gpick gip guvcview gparted soundconverter clipmenu lxappearance qt5ct picom filezilla
#sudo dnf in scrcpy mintstick gprename ytfzf
read -rns1 -p "Press any key to continue..";echo

# theming

sudo dnf in f38-backgrounds-gnome f38-backgrounds-extras-gnome arc-theme adw-gtk3-theme adwaita-gtk2-theme adwaita-qt5 adwaita-qt6

# ----------------------------------

# Flatpak 

sudo dnf in flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.signal.Signal com.github.tchx84.Flatseal com.microsoft.Edge com.librumreader.librum com.belmoussaoui.Authenticator
flatpak override --user --env=SIGNAL_START_IN_TRAY=1 org.signal.Signal 

# post commands
gsettings set org.gnome.desktop.interface color-scheme prefer-dark 
echo "export QT_QPA_PLATFORMTHEME=qt5ct" >> ~/.bash_profile

read -rns1 -p "Please reboot..";echo



