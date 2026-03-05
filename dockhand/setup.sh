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
  info "creating dockhand data folder at $(green "/opt/dockhand")"
  mkdir -p /opt/dockhand
  success "created necessary folders for dockhand"
}

symlink_docker() {
  info "symlinking dockhand to $(green "/j2-homelab/dockhand")"
  symlink /docker/dockhand /j2-homelab/dockhand
}

setup_overlayfs() {
  info "installing fuse-overlayfs"
  apt install -y fuse-overlayfs

  info "configuring Docker to use fuse-overlayfs storage driver"
  mkdir -p /etc/docker
  cat > /etc/docker/daemon.json <<EOF
{
  "storage-driver": "fuse-overlayfs"
}
EOF

  success "configured fuse-overlayfs for Docker"
  info "restart Docker with: $(green "systemctl restart docker")"
}

options=("setup folders" "symlink docker" "setup overlayfs" "quit")

logblock "debug" "Dockhand LXC Setup"

COLUMNS=1
select choice in "${options[@]}"; do
    case $choice in
        "setup folders")  setup_folders; break ;;
        "symlink docker")  symlink_docker; break ;;
        "setup overlayfs")  setup_overlayfs; break ;;
        "quit")         info "Exiting."; break ;;
        *)              warning "Invalid option, try again."; break;;
    esac
    echo ""
done

info "To install Docker, run: $(green "bash /j2-homelab/scripts/install-docker.sh")"
info "After Docker is installed, run: $(green "setup overlayfs") then $(green "systemctl restart docker")"
