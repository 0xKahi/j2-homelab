# Dockhand Setup Guide

Dockhand is a self-hosted Docker management UI deployed on a dedicated LXC container (CT 201).
It connects to the mediaserver VM (CT 200) via the Hawser agent to manage all Docker Compose stacks
(`aggregator`, `jellyfin`, `karakeep`) from a single interface.

**Architecture:**

```
[ Proxmox vmbr0 — 10.10.1.0/24 ]
        |                    |
 Dockhand LXC          Mediaserver VM
  CT 201                  CT 200
  10.10.1.201             10.10.1.200
  port 3000 (UI)          Hawser agent
        |                    |
        +-------- TCP -------+
                port 2376
```

---

## Prerequisites

- Proxmox VE with vmbr0 bridge (`10.10.1.0/24`)
- NAS at `10.10.1.110` with SMB share `j2-homelab` (read-only)
- Mediaserver VM (CT 200) at `10.10.1.200` running Docker
- Ubuntu 22.04 LXC template available in Proxmox local storage

---

## Overview

```
Phase 1 → Create Dockhand LXC (CT 201) on Proxmox
Phase 2 → Mount SMB share + run setup.sh (folders, symlinks, Docker)
Phase 3 → Deploy Dockhand via docker-compose
Phase 4 → Install Hawser agent on mediaserver VM (CT 200)
Phase 5 → Connect Dockhand to mediaserver via Hawser
Phase 6 → Verify stacks are visible and manageable
```

---

## Phase 1 — Create Dockhand LXC

### Create LXC in Proxmox UI

1. Click **Create CT** in the Proxmox UI.

2. Fill in the wizard:

   **General tab:**
   - CT ID: `201`
   - Hostname: `dockhand`
   - Password: set a root password

   **Template tab:**
   - Storage: `local`
   - Template: `ubuntu-22.04-standard`

   **Disk tab:**
   - Storage: `local`
   - Disk size: `16 GiB`

   **CPU tab:**
   - Cores: `2`

   **Memory tab:**
   - Memory: `2048 MiB` (2GB)

   **Network tab:**
   - Bridge: `vmbr0`
   - IPv4: Static — `10.10.1.201/24`
   - Gateway: `10.10.1.1`

   **DNS tab:**
   - DNS server: `1.1.1.1`

3. Click **Finish** — do NOT start yet.

### Enable nesting for Docker

Edit the LXC config on the Proxmox host before starting:

```bash
nano /etc/pve/lxc/201.conf
```

Add the following lines:

```
features: nesting=1,keyctl=1
lxc.apparmor.profile: generated
lxc.cgroup2.devices.allow: a
lxc.cap.drop:
mp0: /flash/j2-homelab,mp=/j2-homelab,ro=1
```

4. Start the container.

#### ✅ OUTCOME
- CT 201 running at `10.10.1.201` on `vmbr0`

---

## Phase 2 — Run setup.sh

### Run setup.sh

```bash
bash /j2-homelab/dockhand/setup.sh
```

Run in order:
1. `setup folders`
2. `symlink docker`

### Install Docker

```bash
bash /j2-homelab/scripts/install-docker.sh
```

- pick **ubuntu**

#### ✅ OUTCOME
- `/docker/dockhand` → symlinked to `/j2-homelab/dockhand`
- `/opt/dockhand` data directory created
- Docker installed and running

---

## Phase 3 — Deploy Dockhand

```bash
cd /docker/dockhand
docker compose up -d
```

Open the UI at `http://10.10.1.201:3000` and complete the initial account setup.

#### ✅ OUTCOME
- Dockhand running at `http://10.10.1.201:3000`

---

## Phase 4 — Install Hawser on Other VMs

SSH into the mediaserver VM etc (`10.10.1.200`) and install the Hawser agent:

```bash
curl -fsSL https://raw.githubusercontent.com/Finsys/hawser/main/scripts/install.sh | bash
```

Configure the agent:

```bash
sudo vim /etc/hawser/config
```

```
PORT=2376
DOCKER_SOCKET=/var/run/docker.sock
TOKEN=<your-secret-token>
```

Enable and start the service:

```bash
sudo systemctl enable hawser
sudo systemctl start hawser
```

Verify it is running:

```bash
sudo systemctl status hawser
```

#### ✅ OUTCOME
- Hawser agent running on `10.10.1.200:2376`

---

## Phase 5 — Connect Dockhand to VM 

1. In the Dockhand UI, go to **Settings → Environments → Add Environment**.
2. Fill in:
   - **Type:** Hawser Standard
   - **Name:** `mediaserver`
   - **Host:** `10.10.1.200`
   - **Port:** `2376`
   - **Token:** `<your-secret-token>`
3. Click **Save** and wait for the connection to establish.

#### ✅ OUTCOME
- `mediaserver` environment visible and connected in Dockhand

---

## Phase 6 — Verify Stacks

Confirm the following stacks are visible under the `mediaserver` environment:

| Stack | Services |
|-------|----------|
| `aggregator` | gluetun, qbittorrent, nzbget, prowlarr, sonarr, radarr, lidarr, bazarr |
| `jellyfin` | jellyfin, jellyseerr, jellystat, jellystat-db |
| `karakeep` | web, chrome, meilisearch |

Test by restarting one container from the Dockhand UI.

#### ✅ OUTCOME
- All 3 stacks visible and manageable from Dockhand

---

## Troubleshooting

### Docker fails to start inside LXC

Missing nesting/apparmor config in the LXC conf. Verify `/etc/pve/lxc/201.conf` contains:

```bash
grep -E 'features|apparmor|cgroup|cap' /etc/pve/lxc/201.conf
```

Restart the container after editing.

---

### Hawser service fails to connect

Check the Hawser service logs on the mediaserver VM:

```bash
sudo journalctl -u hawser -f
```

Verify port `2376` is reachable from the Dockhand LXC:

```bash
nc -zv 10.10.1.200 2376
```

---

### SMB share not mounting

Verify credentials and NAS reachability:

```bash
ping 10.10.1.110
sudo mount -a -v
```

---

## Summary

| What                        | Value                                      |
|-----------------------------|--------------------------------------------|
| Dockhand LXC CT ID          | `201`                                      |
| Dockhand LXC IP             | `10.10.1.201` (on `vmbr0`)                 |
| Dockhand UI                 | `http://10.10.1.201:3000`                  |
| Dockhand data dir           | `/opt/dockhand`                            |
| Docker compose dir          | `/docker/dockhand`                         |
| SMB source (j2-homelab)     | `//10.10.1.110/j2-homelab` (ro)            |
| Mediaserver VM CT ID        | `200`                                      |
| Mediaserver VM IP           | `10.10.1.200` (on `vmbr0`)                 |
| Hawser agent port           | `2376`                                     |
| Stacks managed              | `aggregator`, `jellyfin`, `karakeep`       |

