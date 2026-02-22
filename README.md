# HomeLab Setup

## symlink stuff 

### Install

```bash
chmod +x ./scripts/symlinks.sh
./scripts/symlinks.sh --create
```

### Unlink

```bash
./scripts/symlinks.sh --delete
```

## Home Lab Setup

### 1. Setup bashrc

this appends the `bash/custom.bash` to `.bashrc`

```bash
chmod +x ./scripts/setup_bash.sh
./scripts/setup_bash.sh

# next
source ~/.bashrc
```


### 2. Setup TTY Colors 

in root do 

```bash
tty-color-tool set ~/j2-homelab/tty-colors.txt
```

### 3. Setup Home Lab
```bash
chmod +x ./scripts/setup.sh
./scripts/setup.sh
```
