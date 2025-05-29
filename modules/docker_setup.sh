#!/bin/bash

setup_docker() {
    echo "Setting up Docker..."
    
    # Check if Docker is already installed
    if ! command -v docker &> /dev/null; then
        # Install required packages for Docker repository
        apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
        
        # Add Docker's official GPG key
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        
        # Set up the Docker repository
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Update package list after adding Docker repo
        apt-get update
        
        # Install Docker Engine
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # Start and enable Docker service
        systemctl start docker
        systemctl enable docker
    fi
    
    # Check if Docker Compose is already installed
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        # Install Docker Compose
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    # Get current user (accounting for sudo)
    local CURRENT_USER
    if [ "$SUDO_USER" ]; then
        CURRENT_USER=$SUDO_USER
    else
        CURRENT_USER=$(whoami)
    fi
    
    # Get home directory for the current user
    local HOME_DIR
    if [ "$CURRENT_USER" = "root" ]; then
        HOME_DIR="/root"
    else
        HOME_DIR="/home/$CURRENT_USER"
    fi
    
    # Add current user to docker group to use Docker without sudo
    if ! getent group docker | grep -q "\b$CURRENT_USER\b"; then
        usermod -aG docker "$CURRENT_USER"
    fi
}
