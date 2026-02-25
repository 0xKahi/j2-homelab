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

symlink_tailscale() {
  info "symlinking tailscale config to ~/.tailscale"
  local SYMLINK_TARGET="$HOME/.tailscale"
  local SYMLINK_SOURCE="$SCRIPT_DIR"

  symlink "$SYMLINK_TARGET" "$SYMLINK_SOURCE"
}

install_tailscale() {
  info "updating package lists and upgrading existing packages"
  apt update && apt upgrade -y
  apt install curl -y
  success "installed curl"

  curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.noarmor.gpg \
    | tee /usr/share/keyrings/tailscale-archive-keyring.gpg > /dev/null
  success "added Tailscale GPG keyring to /usr/share/keyrings/tailscale-archive-keyring.gpg"

  curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.tailscale-keyring.list \
    | tee /etc/apt/sources.list.d/tailscale.list
  success "added Tailscale repository to /etc/apt/sources.list.d/tailscale.list"

  apt update
  apt install tailscale -y
  success "installed Tailscale"

  systemctl enable tailscaled
  systemctl start tailscaled
  success "enabled and started tailscaled service"

  echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
  echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf
  sysctl -p
}

setup_persistant_auth() {
  local SYMLINK_TARGET="/etc/systemd/system/tailscaled.service.d/override.conf"
  local SYMLINK_SOURCE="$SCRIPT_DIR/override.conf"

  mkdir -p /etc/systemd/system/tailscaled.service.d/
  symlink "$SYMLINK_TARGET" "$SYMLINK_SOURCE"

  systemctl daemon-reload
  systemctl restart tailscaled
}

start_tailscale() {
  info "starting Tailscale"
  bash /root/.tailscale/tailscale-up.sh
}

options=("symlink" "install tailscale" "setup persistant auth" "start" "quit")

logblock "debug" "Tailscale Setup"

COLUMNS=1
select choice in "${options[@]}"; do
    case $choice in
        "symlink")  symlink_tailscale; break ;;
        "install tailscale")  install_tailscale; break ;;
        "setup persistant auth")   setup_persistant_auth; break ;;
        "start")   start_tailscale; break ;;
        "quit")         info "Exiting."; break ;;
        *)              warning "Invalid option, try again."; break;;
    esac
    echo ""
done


