## Proxmox Containers Post Install Scripts

Debian with Docker

```bash
bash -c "$(wget -qLO - https://github.com/devken0/first-scripts/raw/main/proxmox-ct/debian-docker.sh)"
```

## On Premise (Bare-metal) Post Install Scripts

Proxmox Shell

```bash
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/post-pve-install.sh)"
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/kernel-clean.sh)"
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/microcode.sh)"
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/host-backup.sh)"
```

