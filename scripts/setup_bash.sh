#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. $SCRIPT_DIR/utils.sh

BASHRC="$HOME/.bashrc"
SOURCE_LINE='[ -f "$HOME/j2-homelab/bash/custom.bash" ] && source "$HOME/j2-homelab/bash/custom.bash"'

if [ ! -f "$BASHRC" ]; then
    warning "$BASHRC not found — skipping."
    exit 1
fi

if grep -qF "$SOURCE_LINE" "$BASHRC"; then
    warning "Source line already exists in $BASHRC — skipping."
else
    echo "$SOURCE_LINE" >> "$BASHRC"
    success "Appended source line to $BASHRC."
fi
