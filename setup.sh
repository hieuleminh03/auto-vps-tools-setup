#!/bin/bash

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges"
    exit 1
fi

# Update system packages
echo "Updating system packages..."
apt-get update
apt-get upgrade -y
apt-get install -y curl wget git unzip htop net-tools

# Source module scripts
source modules/zsh_setup.sh
source modules/git_setup.sh
source modules/docker_setup.sh
source modules/optional_tools.sh

# Run setup modules
setup_zsh
setup_git
setup_docker
install_optional_tools

echo "Setup completed. Log out and log back in for all changes to take effect."
exit 0
