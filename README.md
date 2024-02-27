## Post install scripts

### Proxmox Containers

```bash
# Debian with Docker
bash -c "$(wget -qLO - https://github.com/devken0/first-scripts/raw/main/proxmox-ct/deb-docker.sh)"
```

### On Premise

```bash
# Proxmox Shell
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/post-pve-install.sh)"
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/kernel-clean.sh)"
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/microcode.sh)"
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/host-backup.sh)"
```

