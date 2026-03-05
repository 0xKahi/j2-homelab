# Media Server Setup Guide

- [gpu passthrough](https://forum.proxmox.com/threads/2025-proxmox-pcie-gpu-passthrough-with-nvidia.169543/)

## Phase 1: Setup

### Create the VM 

1. Click **Create VM** (top right of the Proxmox UI)

2. Fill in the wizard:

   **General tab:**
   - CT ID: `200` (or any available ID)
   - name: `mediaserver`

   **OS tab (use CD/DVD disc image file):**
   - Storage: `local`
   - ISO Image: `ubuntu-24.04.4-live-server-amd64.iso`

   **Storage tab:**
   - machine: `q35`
   - controller: `VirtIO SCSI`
   - bios: `OVMF (UEFI)`

   **Disk tab:**
   - Bus/Device: `SCSI`
   - Format: `raw`
   - storage: `local`
   - Disk size: `64 GiB` (sufficient)

   **CPU tab:**
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

## Phase 3: Run Setup Script

```bash
bash /j2-homelab/mediaserver/setup.sh
```

1. setup_folders 
2. symlink_docker
3. install_docker

