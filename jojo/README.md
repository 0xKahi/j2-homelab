# JoJo Server Setup Guide

Vm to run generic docker containers on Proxmox

### Create the VM 

1. Click **Create VM** (top right of the Proxmox UI)

2. Fill in the wizard:

   **General tab:**
   - CT ID: `202` (or any available ID)
   - name: `jojo`

   **OS tab (use CD/DVD disc image file):**
   - Storage: `local`
   - ISO Image: `ubuntu-24.04.4-live-server-amd64.iso`

   **System tab:**
   - machine: `q35`
   - controller: `VirtIO SCSI`
   - bios: `OVMF (UEFI)`
   - efi storage: `local`
   - format `qcow2`

   **Disk tab:**
   - Bus/Device: `SCSI`
   - storage: `flash`
   - Disk size: `64 GiB` (sufficient)
   - iothread: `true`
   - SSD Emulation: `true`

   **CPU tab:**
   - Host: `1`
   - Cores: `6`
   - Type: `host`

   **Memory tab:**
   - Memory: `8192 MiB` (8GB)

   **Network tab:**
   - Bridge: `vmbr0`

 3. Click **Finish** — do NOT start it yet.



## Phae 2: Setup Mounts

```bash
sudo apt install cifs-utils
```

### Create Credentials File

```bash
vim ~/.smbcredentials
```

add your credentials

```sh
user=<username>
password=<password>
```

set permissions

```bash
chmod 600 ~/.smbcredentials
```

### Mount Shares

```bash
# create directories first
sudo mkdir -p /data
sudo mkdir -p /j2-homelab
sudo vim /etc/fstab
```

```bash
//10.10.1.110/data      /data       cifs  credentials=/home/kahi/.smbcredentials,uid=1000,gid=1000,file_mode=0755,dir_mode=0755,nobrl 0 0
//10.10.1.110/j2-homelab /j2-homelab cifs  credentials=/home/kahi/.smbcredentials,uid=1000,gid=1000,file_mode=0755,dir_mode=0755,ro 0 0
```

```bash
sudo systemctl daemon-reload
sudo mount -a
```

## Phase 3: Install Docker && Setup

```bash
bash /j2-homelab/scripts/install-docker.sh
```

**create .env file** before this in `/j2-homelab/jojo` and all the nested folders 

```bash
bash /j2-homelab/jojo/setup.sh
```

- setup_folders
- setup_docker_group

```bash
cd /docker
docker compose up -d
```
