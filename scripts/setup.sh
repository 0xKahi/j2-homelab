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

install_docker() {
    logblock "info" "Installing Docker..."

    if $IS_TEST; then
        echo "apt install -y ca-certificates curl gnupg"
        echo "install -m 0755 -d /etc/apt/keyrings"
        echo "curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
        echo "chmod a+r /etc/apt/keyrings/docker.gpg"
        echo "echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable' > /etc/apt/sources.list.d/docker.list"
        echo "apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin"
    else
        apt install -y ca-certificates curl gnupg

        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg

        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] \
            https://download.docker.com/linux/debian bookworm stable" \
            > /etc/apt/sources.list.d/docker.list

        apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    fi

    logblock "success" "Docker installed."
    debug "enable by running: $(green "systemctl enable --now docker")"
}

options=("setup bash" "install packages" "install docker" "quit")

logblock "debug" "HomeLab Setup"

COLUMNS=1
select choice in "${options[@]}"; do
    case $choice in
        "setup bash")  setup_bash; break ;;
        "install packages")  install_packages; break ;;
        "install docker")    install_docker; break ;;
        "quit")         info "Exiting."; break ;;
        *)              warning "Invalid option, try again."; break;;
    esac
    echo ""
done
