#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. $SCRIPT_DIR/../scripts/utils.sh


symlink() {
  local TARGET="$1"
  local SOURCE="$2"

  if [ -L "$TARGET" ]; then
      warning "symlink already exists: $TARGET — skipping."
  elif [ -f "$TARGET" ]; then
      warning "file already exists at $TARGET — skipping."
  else
      ln -s "$SOURCE" "$TARGET"
      success "symlinked $(cyan "$SOURCE") -> $(cyan "$TARGET")"
  fi
}

setup_folders() {
  sudo mkdir -p /docker
  sudo mkdir -p /data/karakeep
  sudo mkdir -p /data/downloads/qbittorrent/{completed,incomplete,torrents}
  sudo mkdir -p /data/downloads/nzbget/{completed,intermediate,nzb,queue,tmp}
  sudo chown -R 1000:1000 /data
  sudo chown -R 1000:1000 /docker
}

symlink_docker() {
  symlink /docker/aggregator /j2-homelab/mediaserver/aggregator
  symlink /docker/jellyfin   /j2-homelab/mediaserver/jellyfin
  symlink /docker/karakeep   /j2-homelab/mediaserver/karakeep
}

install_docker() {
  logblock "info" "Installing Docker..."
  sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)
  # Add Docker's official GPG key:
  sudo apt update
  sudo apt install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:
  sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  success "added Docker GPG key and repository"
  sudo apt update

  info "installing Docker packages"
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  debug "adding user to docker group"
  sudo groupadd docker
  sudo usermod -aG docker $USER
  info "successfully added user to docker group"
  info "access group by either logging out and back in, or running $(green "newgrp docker")"
  
  sudo systemctl enable docker
  sudo systemctl start docker
  
  success "installed Docker"
  debug "check status by: $(green "sudo systemctl status docker")"
}

install_nvidia_toolkit() {
  info "installing NVIDIA Container Toolkit"
  sudo curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

  sudo curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
   sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://##' | \
   sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

  sudo apt update
  sudo apt install -y nvidia-container-toolkit
  success "installed NVIDIA Container Toolkit"

  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker
  debug "configured NVIDIA Container Toolkit for Docker runtime"
}


options=("setup folders" "symlink docker" "install docker" "quit")

logblock "debug" "Media Server Setup"

COLUMNS=1
select choice in "${options[@]}"; do
    case $choice in
        "setup folders")  setup_folders; break ;;
        "symlink docker")  symlink_docker; break ;;
        "install docker")  install_docker; break ;;
        "quit")         info "Exiting."; break ;;
        *)              warning "Invalid option, try again."; break;;
    esac
    echo ""
done
