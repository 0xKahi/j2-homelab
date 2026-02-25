#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. $SCRIPT_DIR/../../scripts/utils.sh

# ── helpers ────────────────────────────────────────────────────────────────────

symlink() {
    local src=$1
    local dest=$2
    if [ -L "$dest" ]; then
        warning "Symlink already exists: $dest"
    elif [ -f "$dest" ]; then
        warning "File already exists at $dest, skipping."
    else
        ln -s "$src" "$dest"
        success "Symlinked $src -> $dest"
    fi
}

# ── steps ──────────────────────────────────────────────────────────────────────

symlink_vault() {
    logblock "info" "Symlinking j2-vault config"
    symlink "$SCRIPT_DIR" "$HOME/.j2-vault"
}

install_samba() {
    logblock "info" "Installing Samba"
    apt update && apt upgrade -y
    apt install -y samba wsdd
    success "Samba and wsdd installed."
}

symlink_samba_config() {
    logblock "info" "Linkng Samba Config"

    local SMB_CONF="/etc/samba/smb.conf"
    local SMB_SRC="$SCRIPT_DIR/smb.conf"

    # already a symlink — do nothing
    if [ -L "$SMB_CONF" ]; then
        warning "smb.conf is already a symlink, skipping."
        return
    fi

    # real file exists — back it up then symlink
    if [ -f "$SMB_CONF" ]; then
        mv "$SMB_CONF" "${SMB_CONF}.orig"
        info "Backed up existing smb.conf to smb.conf.orig"
    fi

    ln -s "$SMB_SRC" "$SMB_CONF"
    success "Symlinked $SMB_SRC -> $SMB_CONF"

    # enable and start services
    systemctl enable smbd nmbd wsdd
    systemctl restart smbd nmbd wsdd
    success "smbd, nmbd, wsdd enabled and started."
}

# ── menu ───────────────────────────────────────────────────────────────────────

options=("symlink" "install" "symlink samba" "quit")

logblock "debug" "j2-vault Samba Setup"

COLUMNS=1
select choice in "${options[@]}"; do
    case $choice in
        "symlink") symlink_vault; break ;;
        "install") install_samba; break ;;
        "symlink samba") symlink_samba_config; break ;;
        "quit") info "Exiting."; break ;;
        *) warning "Invalid option, try again."; break ;;
    esac
    echo ""
done
