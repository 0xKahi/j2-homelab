#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. $SCRIPT_DIR/utils.sh

if [ "$EUID" -ne 0 ]; then
  exec sudo bash "$0" "$@"
fi


install_docker_debian() {
    logblock "info" "Installing Docker For Debian"

    apt install -y ca-certificates curl gnupg

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/debian bookworm stable" \
        > /etc/apt/sources.list.d/docker.list

    apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    logblock "success" "Docker installed."
    debug "enable by running: $(green "systemctl enable --now docker")"
}

install_docker_ubuntu() {
  logblock "info" "Installing Docker For Ubuntu"
  apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)
  apt update
  apt install -y ca-certificates curl
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

  tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  success "added Docker GPG key and repository"
  apt update

  info "installing Docker packages"
  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  systemctl enable docker
  systemctl start docker

  success "installed Docker"
  debug "check status by: $(green "systemctl status docker")"
}


options=("ubuntu" "debian" "quit")

logblock "debug" "Docker Installation"

COLUMNS=1
select choice in "${options[@]}"; do
    case $choice in
        "ubuntu")  install_docker_ubuntu; break ;;
        "debian")  install_docker_debian; break ;;
        "quit")         info "Exiting."; break ;;
        *)              warning "Invalid option, try again."; break;;
    esac
    echo ""
done
