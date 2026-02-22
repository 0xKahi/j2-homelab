#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
    run_apt "$SCRIPT_DIR/../cfgs/packages.conf"
    logblock "success" "Base Packages installed."
}

setup_colors() {
    local config="~/j2-homelab/tty-colors.txt"
    file_check "$config" || return 1
    logblock "info" "Setting up colors..."

    if $IS_TEST; then
       echo "sudo tty-color-tool set "${config}""
    else
       tty-color-tool set "${config}" 
    fi

    logblock "success" "Colors set up."
}

options=("Install Packages" "Quit")

logblock "debug" "HomeLab Setup"

COLUMNS=1
select choice in "${options[@]}"; do
    case $choice in
        "Install Packages")  install_packages; break ;;
        "Quit")         info "Exiting."; break ;;
        *)              warning "Invalid option, try again."; break;;
    esac
    echo ""
done
