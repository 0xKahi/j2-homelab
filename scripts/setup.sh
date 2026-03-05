#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. $SCRIPT_DIR/utils.sh

IS_TEST=false

file_check() {
    if [[ ! -f "$1" ]]; then
        error "config not found: $1"
        echo ""
        exit 1 
    fi
}

run_apt() {
    local config="$1"
    file_check "$config" || return 1

    local packages=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        packages+=("$line")
    done < "$config" 

    echo ""
    debug "installing packages"
    if $IS_TEST; then
       echo "sudo apt install "${packages[@]}" -y"
    else
       apt install "${packages[@]}" -y
    fi
}

install_packages() {
    logblock "info" "Installing Base Packages..."
    run_apt "$SCRIPT_DIR/configs/packages.conf"
    logblock "success" "Base Packages installed."
}

setup_bash() {
    logblock "info" "setting up bash"

    local bashrc="$HOME/.bashrc"
    local source_line='[ -f "$HOME/.homelab/bash/custom.bash" ] && source "$HOME/.homelab/bash/custom.bash"'
    file_check "$bashrc" || return 1

    if grep -qF "$source_line" "$bashrc"; then
        warning "Source line already exists in $source_line — skipping."
    else
        echo "$source_line" >> "$bashrc"
        success "Appended source line to $bashrc."
    fi
}

options=("setup bash" "install packages" "install docker" "quit")

logblock "debug" "HomeLab Setup"

COLUMNS=1
select choice in "${options[@]}"; do
    case $choice in
        "setup bash")  setup_bash; break ;;
        "install packages")  install_packages; break ;;
        "quit")         info "Exiting."; break ;;
        *)              warning "Invalid option, try again."; break;;
    esac
    echo ""
done
