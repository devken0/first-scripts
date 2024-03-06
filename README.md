## Proxmox Containers Post Install Scripts

Ubuntu with Cockpit

```bash
bash -c "$(wget -qLO - https://github.com/devken0/first-scripts/raw/main/proxmox-ct/ubuntu-cockpit.sh)"
```

Debian with Cockpit

```bash
bash -c "$(wget -qLO - https://github.com/devken0/first-scripts/raw/main/proxmox-ct/debian-cockpit.sh)"
```

Debian with Docker

```bash
bash -c "$(wget -qLO - https://github.com/devken0/first-scripts/raw/main/proxmox-ct/debian-docker.sh)"
```

Alpine with Docker

```bash
wget -O alpine-docker.sh https://raw.githubusercontent.com/devken0/first-scripts/main/proxmox-ct/alpine-docker.sh
chmod +x alpine-docker.sh
./alpine-docker.sh
```

## On Premise (Bare-metal) Post Install Scripts

Proxmox Shell

```bash
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/post-pve-install.sh)"
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/kernel-clean.sh)"
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/microcode.sh)"
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/host-backup.sh)"
```

