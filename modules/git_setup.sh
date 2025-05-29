#!/bin/bash

setup_git() {
    echo "Setting up Git..."

    # Install Git if not already installed
    if ! command -v git &> /dev/null; then
        apt-get install -y git
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
    
    # Generate SSH keys if they don't exist
    local SSH_DIR="$HOME_DIR/.ssh"
    local SSH_KEY="$SSH_DIR/id_ed25519"
    
    if [ ! -f "$SSH_KEY" ]; then
        # Create .ssh directory if it doesn't exist
        mkdir -p "$SSH_DIR"
        chown "$CURRENT_USER:$CURRENT_USER" "$SSH_DIR"
        chmod 700 "$SSH_DIR"
        
        # Generate key non-interactively
        if [ "$CURRENT_USER" = "root" ]; then
            ssh-keygen -t ed25519 -f "$SSH_KEY" -N '' -C "$CURRENT_USER@$(hostname)"
            chmod 600 "$SSH_KEY"
            chmod 644 "$SSH_KEY.pub"
        else
            su - "$CURRENT_USER" -c "ssh-keygen -t ed25519 -f $SSH_KEY -N '' -C \"$CURRENT_USER@$(hostname)\""
            su - "$CURRENT_USER" -c "chmod 600 $SSH_KEY"
            su - "$CURRENT_USER" -c "chmod 644 $SSH_KEY.pub"
        fi
        
        # Display public key
        echo "SSH key generated. Public key:"
        cat "$SSH_KEY.pub"
        
        # Ask if user wants to add to Git account
        read -p "Add this key to your Git account? (y/n): " -r ADD_TO_GIT
        if [[ $ADD_TO_GIT =~ ^[Yy]$ ]]; then
            read -p "Press Enter once you've added the key..." -r
        fi
    else
        echo "SSH key already exists at $SSH_KEY"
    fi
    
    # Configure Git user information
    read -p "Enter your Git username (leave blank to skip): " -r GIT_USERNAME
    if [ -n "$GIT_USERNAME" ]; then
        read -p "Enter your Git email: " -r GIT_EMAIL
        if [ -n "$GIT_EMAIL" ]; then
            if [ "$CURRENT_USER" = "root" ]; then
                git config --global user.name "$GIT_USERNAME"
                git config --global user.email "$GIT_EMAIL"
            else
                su - "$CURRENT_USER" -c "git config --global user.name \"$GIT_USERNAME\""
                su - "$CURRENT_USER" -c "git config --global user.email \"$GIT_EMAIL\""
            fi
        fi
    fi
    
    # Set up some useful Git configurations
    if [ "$CURRENT_USER" = "root" ]; then
        git config --global init.defaultBranch main
        git config --global core.editor nano
        git config --global pull.rebase false
        git config --global alias.co checkout
        git config --global alias.br branch
        git config --global alias.ci commit
        git config --global alias.st status
        git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
    else
        su - "$CURRENT_USER" -c "git config --global init.defaultBranch main"
        su - "$CURRENT_USER" -c "git config --global core.editor nano"
        su - "$CURRENT_USER" -c "git config --global pull.rebase false"
        su - "$CURRENT_USER" -c "git config --global alias.co checkout"
        su - "$CURRENT_USER" -c "git config --global alias.br branch"
        su - "$CURRENT_USER" -c "git config --global alias.ci commit"
        su - "$CURRENT_USER" -c "git config --global alias.st status"
        su - "$CURRENT_USER" -c "git config --global alias.lg \"log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit\""
    fi
}
