#!/bin/bash
# AstrBot Installer for Linux
#run this script with sudo or as root

#check if the user is root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root or with sudo."
        exit 1
    fi
}

#check if the user is running on a supported Linux distribution
check_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" && "$ID" != "debian"
            && "$ID" != "fedora" && "$ID" != "arch" ]]; then
            echo "Unsupported Linux distribution: $ID"
            exit 1
        fi
    else
        echo "Cannot determine Linux distribution."
        exit 1
    fi
}

#install dependencies
install_dependencies() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian)
                apt update
                apt install -y python3 python3-pip git
                ;;
            fedora)
                dnf install -y python3 python3-pip git
                ;;
            arch)
                pacman -S --noconfirm python python-pip git
                ;;
        esac
    fi
}

#install uv for Astrbot
install_uv() {
    pip3 install uv
}

#install AstrBot using uv
install_astrbot() {
    uv tool install astrbot
    uv tool run astrbot init
}

#main function
main() {
    check_root
    check_distro
    install_dependencies
    install_uv
    install_astrbot
    echo "AstrBot has been successfully installed!"
}

main