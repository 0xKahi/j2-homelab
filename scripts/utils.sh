#!/bin/bash

default_color=$(tput sgr 0)
red="$(tput setaf 1)"
yellow="$(tput setaf 3)"
green="$(tput setaf 2)"
blue="$(tput setaf 4)"

info() {
    # printf "%s==> %s%s\n" "$blue" "$1" "$default_color"
    printf "\e[44;30mINFO\e[0m \e[94m%s\e[0m\n" "$1"
}

success() {
    # printf "%s==> %s%s\n" "$green" "$1" "$default_color"
    printf "\e[42;30mSUCCESS\e[0m \e[92m%s\e[0m\n" "$1"
}

error() {
    # printf "%s==> %s%s\n" "$red" "$1" "$default_color"
    printf "\e[41;30mERROR\e[0m \e[91m%s\e[0m\n" "$1"
}

warning() {
    # printf "%s==> %s%s\n" "$yellow" "$1" "$default_color"
    printf "\e[43;30mWARN\e[0m \e[93m%s\e[0m\n" "$1"
}

debug() {
    printf "\e[45;30mDEBUG\e[0m \e[95m%s\e[0m\n" "$1"
}

log(){
    local type="$1"
    local message="$2"
    case "$type" in
        "info")
            info "$message"
            ;;
        "success")
            success "$message"
            ;;
        "error")
            error "$message"
            ;;
        "warning")
            warning "$message"
            ;;
        "debug")
            debug "$message"
            ;;
        *)
           warning "unknown message type: $type" 
            ;;
    esac
}

logblock() {
    local type="$1"
    local message="$2"

    echo ""
    log "$type" "$message"
    echo ""
}
