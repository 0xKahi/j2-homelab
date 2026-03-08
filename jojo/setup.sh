#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. $SCRIPT_DIR/../scripts/utils.sh

if [ "$EUID" -ne 0 ]; then
  exec sudo bash "$0" "$@"
fi

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
  info "creating docker folder at $(green "/docker")"
  mkdir -p /docker

  debug "setting up base symlinks"
  symlink /docker/.env /j2-homelab/jojo/.env
  symlink /docker/docker-compose.yml /j2-homelab/jojo/docker-compose.yml

  info "creating glance folder at $(green "/docker/glance")"
  mkdir -p /docker/glance
  debug "setting up symlinks for glance"
  symlink /docker/glance/assets /j2-homelab/jojo/dashboard/glance/assets
  symlink /docker/glance/config /j2-homelab/jojo/dashboard/glance/config

  info "setting up permissions for $(green "/docker")"
  chown -R 1000:1000 /docker

  info "creating memos folder at $(green "/data/memos")"
  mkdir -p /data/memos

  success "created necessary folders for jojo server"
}

setup_docker_group() {
  debug "adding user to docker group"
  groupadd docker
  usermod -aG docker $USER

  info "successfully added user to docker group"
  info "access group by either logging out and back in, or running $(green "newgrp docker")"
}

options=("setup folders" "setup docker group" "quit")

logblock "debug" "Media Server Setup"

COLUMNS=1
select choice in "${options[@]}"; do
    case $choice in
        "setup folders")  setup_folders; break ;;
        "setup docker group")  setup_docker_group; break ;;
        "quit")         info "Exiting."; break ;;
        *)              warning "Invalid option, try again."; break;;
    esac
    echo ""
done
