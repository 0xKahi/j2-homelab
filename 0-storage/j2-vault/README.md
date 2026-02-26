# j2-vault — Samba Network Shares

LXC container running Samba to expose network shares:

- **j2-homelab** — read-only share of the `j2-homelab` git repository, shared across containers via ZFS dataset on the host
- **container-specific** — additional shares (e.g. `kahi`) are set up manually per container using fixed-size Proxmox mount points

```
Proxmox Host (flash ZFS pool)
└── flash/j2-homelab  ← git repo lives here (git pull on host)
          ↕ read-only mount
     LXC: /j2-homelab

LXC: j2-vault (CT 110, 10.10.1.110)
Samba shares:
├── \\10.10.1.110\j2-homelab  (read-only, shared ZFS dataset)
└── \\10.10.1.110\kahi        (read-write, container-specific mount)
```

> **Note on git:** `git pull` is run on the Proxmox host at `/flash/j2-homelab`.
> Changes are instantly visible inside the container and all other LXC/VMs
> that mount the same dataset — no sync needed.

> **Note on scripts:** Scripts in `/j2-homelab` are executable directly from
> any container that mounts the dataset. Set permissions once on the host:
> `chmod +x /flash/j2-homelab/scripts/*.sh`

---

## Phase 1 — Proxmox Host Setup

### 1.1 Create ZFS Dataset (Shared Data)

Run on the Proxmox host shell:

```bash
zfs create flash/j2-homelab
```

### 1.2 Clone Repository into Dataset

```bash
git clone <repo-url> /flash/j2-homelab
```

### 1.3 Create LXC Container

In the Proxmox UI go to **Create CT** with the following settings:

| Setting   | Value              |
| --------- | ------------------ |
| CT ID     | 110                |
| Hostname  | `j2-vault`         |
| Template  | Ubuntu 22          |
| Disk      | 32 GiB (flash pool) |
| CPU       | 1 core             |
| RAM       | 512 MiB            |
| Swap      | 256 MiB            |
| IPv4/CIDR | `10.10.1.110/24`   |
| Gateway   | `10.10.1.1`        |
| DNS       | `1.1.1.1`          |

Leave the container **unprivileged** and do **not** start it yet.

### 1.4 Add Mount Points


| Storage | Host Path    | Container Path | Options   |
| ------- | ------------ | -------------- | --------- |
| flash   | `j2-homelab` | `/j2-homelab`  | read-only |

```bash
vim /etc/pve/lxc/110.conf
```

**Add this line:**
```
mp0: /flash/j2-homelab,mp=/j2-homelab,ro=1
```

> For container-specific storage (e.g. `/kahi`) see [Container-Specific Storage](#container-specific-storage) below.

### 1.5 Start the Container

```bash
pct start 110
```

---

## Phase 2 — Container Setup

### 2.1 Enter the Container

```bash
pct enter 110
```

### 2.2 Verify Mount Points

```bash
ls /j2-homelab   # should show the repo contents
ls /kahi         # should be an empty directory
```

### 2.3 Make Scripts Executable

```bash
chmod +x /j2-homelab/0-storage/j2-vault/*.sh
chmod +x /j2-homelab/scripts/*.sh
```

### 2.4 Run Setup Menu

Run each option in order:

```bash
bash /j2-homelab/0-storage/j2-vault/setup.sh
```

**Step 1 — symlink**
Symlinks the j2-vault config dir to `/root/.j2-vault`.

**Step 2 — install**
Installs `samba` and `wsdd` (Windows network discovery).

**Step 3 — configure**
- If `smb.conf` is already a symlink → skips
- If real `smb.conf` exists → renames to `smb.conf.orig`, then symlinks
- Symlinks `smb.conf` from the repo to `/etc/samba/smb.conf`
- Enables and starts `smbd`, `nmbd`, `wsdd`

---

## Container-Specific Storage

For data that belongs only to this container (e.g. personal notes), add a fixed-size mount point via the Proxmox UI under **Resources > Add > Mount Point**. Set the size and container path (e.g. `/kahi`), then start the container.

Once inside the container:

### 1. Create a user with password

```bash
adduser <user> 
# add user to sudo group
adduser <user> sudo
```

### 2. Grant ownership of the mount point

```bash
chown -R <user>:<usergroup> <mount-point> 
# chown -R kahi:kahi /kahi
```

### 3. Set samba password for the user

```bash
smbpasswd -a <user> 
```

### 4. Add the share to smb.conf

```bash
systemctl restart smbd
systemctl restart nmbd 
```

---

## Adding Shared Group Access

Use this when multiple users need access to the same share (e.g. a shared `/data` volume).

### 1. Create a shared Linux group

```bash
groupadd <groupname>
# e.g. groupadd smbusers
```

### 2. Add users to the group

```bash
usermod -aG <groupname> <user>
# e.g. usermod -aG smbusers kahi
```

Repeat for each user that needs access.

### 3. Set group ownership on the mount point

```bash
chown -R <user>:<groupname> <mount-point>
chmod -R g+rws <mount-point>
# The setgid bit (g+s) ensures new files created inside inherit the group
```

### 4. Set Samba passwords for each user

**each uesr needs a samba password** skup if already set

```bash
smbpasswd -a <user>
```

Repeat for each user.

### 5. Update smb.conf for the share

Replace `force user` / `force group` with group-based directives:

```ini
[sharename]
   path = /data
   valid users = @<groupname>
   force group = <groupname>
   create mask = 0774
   force create mode = 0774
   directory mask = 0775
   force directory mode = 0775
   writable = yes
   browseable = yes
   guest ok = no
```

- `valid users = @<groupname>` — restricts access to group members only
- `force group = <groupname>` — all created files inherit the group, keeping permissions consistent across users

For mixed read/write access, use `write list` and `read list` instead:

```ini
   valid users = @<groupname>
   write list = alice bob
   read list = charlie
```

### 6. Restart Samba

```bash
systemctl restart smbd
systemctl restart nmbd
```

---

## Phase 3 — Verify

### Validate Samba Config

```bash
testparm
```

### Check Services

```bash
systemctl status smbd nmbd wsdd
```

### Test Share Access

**From macOS:**
1. Finder → `Cmd+K`
2. Enter `smb://10.10.1.110`
3. Login with username `kahi` and the password set during configure

**From Windows:**
1. `Win+R` → `\\10.10.1.110`
2. Enter credentials when prompted

**From Linux:**
```bash
smbclient -L //10.10.1.110 -U kahi
```

---

## Connecting to Shares

### macOS — Auto-mount on Login

1. Connect to the share via Finder
2. Open **System Settings > General > Login Items**
3. Add the mounted share to login items

### Linux — Permanent fstab Mount

```bash
# Install cifs-utils
sudo apt install cifs-utils

# Create credentials file
sudo nano /etc/samba/credentials
# Add:
#   username=kahi
#   password=yourpassword
sudo chmod 600 /etc/samba/credentials

# Create mount point
sudo mkdir -p /mnt/kahi

# Add to /etc/fstab
//10.10.1.110/kahi /mnt/kahi cifs credentials=/etc/samba/credentials,uid=1000,gid=1000 0 0

# Mount
sudo mount -a
```

---

## Troubleshooting

**Server not appearing in Windows Network:**
```bash
systemctl status wsdd
```

**Permission denied on kahi share:**
```bash
# Inside the container — verify ownership
ls -la /kahi
chown -R kahi:kahi /kahi
```

**Samba config errors:**
```bash
testparm /etc/samba/smb.conf
```

**Reset samba password:**
```bash
smbpasswd -a kahi
```
