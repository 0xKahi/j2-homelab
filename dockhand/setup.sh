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
  info "creating docker folder at $(green "/docker")"
  sudo mkdir -p /docker
  info "creating dockhand data folder at $(green "/opt/dockhand")"
  sudo mkdir -p /opt/dockhand
  sudo chown -R 1000:1000 /docker
  sudo chown -R 1000:1000 /opt/dockhand
  success "created necessary folders for dockhand"
}

symlink_docker() {
    info "symlinking dockhand to $(green "/j2-homelab/dockhand")"
  symlink /docker/dockhand /j2-homelab/dockhand
}

options=("setup folders" "symlink docker" "quit")

logblock "debug" "Dockhand LXC Setup"

COLUMNS=1
select choice in "${options[@]}"; do
    case $choice in
        "setup folders")  setup_folders; break ;;
        "symlink docker")  symlink_docker; break ;;
        "quit")         info "Exiting."; break ;;
        *)              warning "Invalid option, try again."; break;;
    esac
    echo ""
done

info "To install Docker, run: $(green "bash /j2-homelab/scripts/install-docker.sh")"
