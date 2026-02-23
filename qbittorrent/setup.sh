#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. $SCRIPT_DIR/../scripts/utils.sh

info "installing curl"
apt install -y curl 
success "curl installed"

info "creating qbittorrent directories"
mkdir -p /opt/qbittorrent/{config,downloads}
success "created qbittorent directories at $(cyan "/opt/qbittorrent/config,downloads")"

info "symlinking docker-compose.yml"
SYMLINK_TARGET="/opt/qbittorrent/docker-compose.yml"
SYMLINK_SOURCE="$SCRIPT_DIR/docker-compose.yml"

if [ -L "$SYMLINK_TARGET" ]; then
    warning "symlink already exists: $SYMLINK_TARGET — skipping."
elif [ -f "$SYMLINK_TARGET" ]; then
    warning "file already exists at $SYMLINK_TARGET — skipping."
else
    ln -s "$SYMLINK_SOURCE" "$SYMLINK_TARGET"
    success "symlinked $(cyan "$SYMLINK_SOURCE") -> $(cyan "$SYMLINK_TARGET")"
fi

