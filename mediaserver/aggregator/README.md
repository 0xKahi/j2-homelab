# Aggregator Setup

in **proxmox host**:

```bash
vim /flash/j2-homelab/mediaserver/aggregator/.env
```

add your env variables: similar to `.env.example`

## Filesystem

```
data
├── downloads
│   ├── qbittorrent
│   │   ├── completed
│   │   ├── incomplete
│   │   └── torrents
│   └── nzbget
│       ├── completed
│       ├── intermediate
│       ├── nzb
│       ├── queue
│       └── tmp
└── youtube
```

## Ref
- [Youtube Tutorial](https://www.youtube.com/watch?v=twJDyoj0tDc)
