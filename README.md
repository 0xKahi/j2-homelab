# HomeLab Setup

## Conventions

| CT ID   | IP              | Purpose            |
| ------- | --------------- | ------------------ |
| 100–109 | 10.10.1.100–109 | Routers/networking |
| 110–119 | 10.10.1.110–119 | Storage            |
| 200+    | 10.10.1.200+    | Other servers/apps |


## Base Setup

### Approve scripts

```bash
## in this directory
chmod +x ./scripts/*.sh
chmod +x ./.homelab/bin/*

## in zfs
chmod +x /flash/j2-homelab/scripts/*.sh
chmod +x /flash/j2-homelab/.homelab/bin/*
```

### symlink stuff 

```bash
## in this directory
## create symlinks
./scripts/symlinks.sh --create
## delete symlinks
./scripts/symlinks.sh --delete
```

### Home Lab Setup

> [!Note]
> - setup bash
> - install docker 

```bash
## in this directory
./scripts/setup.sh
```

## GPU Passthrough (NVIDIA)

### Step 1: Enable IOMMU on Proxmox Host

1. **Edit GRUB configuration:**

```bash
vim /etc/default/grub
```

```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt"
```

2. **Update GRUB and reboot:**

```bash
update-grub
reboot
```

3. **Verify IOMMU is enabled:**

```bash
dmesg | grep -e DMAR -e IOMMU
```

### Step 2: Blacklist NVIDIA Nouveau Driver

1. **Create blacklist file:**

```bash
vim /etc/modprobe.d/blacklist-nvidia-nouveau.conf
```

Add:
```
blacklist nouveau
options nouveau modeset=0
```

2. **Update kernel and reboot:**

```bash
update-initramfs -u
reboot
```

### Step 3: Enable VFIO Modules

1. **Edit modules file:**

```bash
vim /etc/modules-load.d/vfio.conf
```

Add:
```
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
```

2. **Update kernel:**

```bash
update-initramfs -u
```
