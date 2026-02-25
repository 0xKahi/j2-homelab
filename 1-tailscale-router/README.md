# Tailscale Setup Guide

Setting up Tailscale on Proxmox VE 9.1 for secure remote access to your homelab
from anywhere in the world — without opening any ports on your router.

**Architecture:** Tailscale runs inside a lightweight Debian 13 LXC container on Proxmox.
The container acts as a **subnet router**, advertising your entire home LAN so all your
VMs (and devices at home) are reachable remotely via Tailscale.

```
[Your Laptop/Phone / Remote Device]
        │  Tailscale VPN (WireGuard)
        ▼
[Tailscale LXC]  10.10.1.100  ← lives inside Proxmox on vmbr0
        │
        ├── subnet route: 192.168.1.0/24  → home LAN devices (router, phones, etc.)
        └── subnet route: 10.10.1.0/24   → Proxmox VMs + LXC containers (OMV, etc.)
```


## Phase 1: Setup

### Create the Container

1. Click **Create CT** (top right of the Proxmox UI)

2. Fill in the wizard:

   **General tab:**
   - CT ID: `100` (or any available ID)
   - Hostname: `tailscale-pve`
   - Password: set a strong root password
   - Uncheck "Unprivileged container" — leave it **unprivileged** (checked is fine)

   **Template tab:**
   - Storage: `local`
   - Template: `debian-13-standard_XX.X-X_amd64.tar.zst`

   **Disks tab:**
   - Disk size: `4 GiB` (sufficient)

   **CPU tab:**
   - Cores: `1`

   **Memory tab:**
   - Memory: `512 MiB`
   - Swap: `256 MiB`

   **Network tab:**
   - Bridge: `vmbr0`
   - IPv4: **Static**
   - IPv4/CIDR: `10.10.1.100/24`
   - Gateway: `10.10.1.1`

   > The LXC lives on the internal NAT bridge (`vmbr0`), not your home LAN. It reaches
   > the internet via Proxmox's masquerade rule, and its Tailscale connection handles
   > routing to both your home LAN and VM subnet.

   **DNS tab:**
   - DNS servers: `1.1.1.1`

3. Click **Finish** — do NOT start it yet.

### Enable TUN Device for Tailscale

Tailscale requires the TUN network device inside the container. This must be configured
before starting the container.

On the **Proxmox host**, run:

```bash
# Replace 100 with your container's CT ID if different
vim /etc/pve/lxc/100.conf
```

Add these lines at the end of the file:

```
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net dev/net none bind,optional,create=dir
lxc.mount.entry: /dev/tun dev/tun none bind,optional,create=file
features: nesting=1
```

Save and close the file.

### Start the Container

In the Proxmox web UI, select **CT 100 (tailscale)** → click **Start**.

Once it's running, click **Console** to open a shell inside the container.


---


## Phase 2 — Install Tailscale Inside the LXC

All commands below run **inside the LXC container** (via the Console tab or SSH).

### Generate an Auth Key

1. Go to `https://login.tailscale.com/admin/settings/keys`
2. Click **Generate auth key**
3. Configure:
   - **Description:** `proxmox-tailscale-lxc`
   - **Reusable:** Yes
   - **Expiry:** 90 days (or "No expiry" for a permanent key)
   - **Pre-authorized:** Yes (skips the approval step on reconnect)
   - **Tags:** optionally tag as `tag:server`
4. Click **Generate key** and copy the key (starts with `tskey-auth-...`)
5. paste the key in this dir in a file named `authKey.secret.conf` (must be this name)

```bash
vim ./1-tailscale-router/authKey.secret.conf
```

### Setup Routes

Edit `routes.conf` — one CIDR per line for each subnet you want to advertise:

```
192.168.1.0/24
10.10.1.0/24
```

This file gets symlinked to `/root/.tailscale/routes.conf` and is read at startup by `tailscale-up.sh`.
### Run Setup Script

```bash
chmod +x ./1-tailscale-router/*.sh
./1-tailscale-router/setup.sh
```

1. start with symlink (symlinks config to `.tailscale`)
2. next choose install option (install tailscale in the container)
3. next choose persistant auth option  (so it saves the auth key and reconnects on reboot)
4. start tailscale (start tailscale with authKey and routes)

### After Starting Tailscale

#### Check Tailscale Status 

```bash
tailscale status
# Should show: tailscale as "connected" with a 100.x.x.x Tailscale IP
```

Note your container's Tailscale IP:
```bash
tailscale ip -4
# Example output: 100.64.0.5
```

#### Approve the Subnet Route in Tailscale Admin

Subnet routes must be explicitly approved in the Tailscale admin console for security.

1. Go to `https://login.tailscale.com/admin/machines`
2. Find the machine named **tailscale** (your LXC container)
3. Click the **...** menu → **Edit route settings**
4. Enable both routes: `192.168.1.0/24` and `10.10.1.0/24`
5. Click **Save**

Your subnet is now routed. Any device connected to your Tailscale network can reach
`192.168.1.0/24` through this container.

## Phase 3 — Verify Remote Access

### From Inside the LXC (Basic Check)

```bash
# Check Tailscale connection
tailscale status

# Verify routes are being advertised
tailscale status --json | python3 -c "import sys,json; s=json.load(sys.stdin); print(s['Self']['PrimaryRoutes'])"

# Ping your Proxmox host through the subnet route
ping 192.168.1.50
```

### From a Remote Device (the Real Test)

On a phone, laptop, or any other device connected to Tailscale:

1. Install Tailscale on the remote device: `https://tailscale.com/download`
2. Sign in with the same Tailscale account
3. Enable "Use exit node" or just connect normally

Then test:

```bash
# Ping the Tailscale container itself
ping 100.64.0.5          # (use your container's actual Tailscale IP)

# Access the Proxmox web UI remotely
# Open in browser: https://192.168.1.50:8006
# This works because 192.168.1.50 is on your advertised subnet

# SSH into the Proxmox host
ssh root@192.168.1.50

# Ping any other device on your home LAN
ping 192.168.1.1         # your router
```

If everything works, you now have full remote access to your homelab from anywhere.
