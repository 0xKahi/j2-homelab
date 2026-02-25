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
```

### symlink stuff 

```bash
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
chmod +x ./scripts/setup.sh
./scripts/setup.sh
```
