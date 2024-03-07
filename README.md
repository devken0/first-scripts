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

OpenMediaVault

```bash
wget -O - https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/install | bash
```

Fedora i3

> Make sure that you have configured the DNF package manager before executing the scripts for a faster installation of system/user packages.
> Simply add these lines in the `/etc/dnf/dnf.conf` file:
> 
> ```bash
> fastestmirror=True
> deltarpm=True
> max_parallel_downloads=10
> defaultyes=True
> keepcache=True
> ```

```bash
bash -c "$(wget -qLO - https://github.com/devken0/first-scripts/raw/main/on-premise/fedora-i3.sh)"
```

