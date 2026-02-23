#  Qbittorent Setup

### Setup Docker

> [!Note]
> make sure you have the main script approved at [HomeLab Setup](/README.md) 

```bash
./scripts/setup.sh
```

pick install docker

### Run Setup Script

```bash
chmod +x ./qbittorrent/setup.sh
./qbittorrent/setup.sh
```

### Running Docker

```bash
cd /opt/qbittorrent
docker compose up -d
```
