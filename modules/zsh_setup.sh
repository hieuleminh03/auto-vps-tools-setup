#!/bin/bash

setup_zsh() {
    echo "Setting up ZSH..."
    
    # Install zsh
    if ! command -v zsh &> /dev/null; then
        apt-get install -y zsh
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
    
    # Install Oh-My-ZSH if not already installed
    if [ ! -d "$HOME_DIR/.oh-my-zsh" ]; then
        if [ "$CURRENT_USER" = "root" ]; then
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        else
            su - "$CURRENT_USER" -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
        fi
        chsh -s "$(which zsh)" "$CURRENT_USER"
    fi
    
    # Install Powerlevel10k
    if [ ! -d "$HOME_DIR/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
        if [ "$CURRENT_USER" = "root" ]; then
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
            sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/g' $HOME_DIR/.zshrc
        else
            su - "$CURRENT_USER" -c 'git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k'
            su - "$CURRENT_USER" -c "sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/g' ~/.zshrc"
        fi
        
        # Create minimal p10k config
        cat > "$HOME_DIR/.p10k.zsh" << 'EOL'
# Minimal Powerlevel10k configuration
prompt_powerlevel9k_teardown() {
  emulate -L zsh
  unfunction prompt_powerlevel9k_teardown
  source "${__p9k_root_dir}/internal/p10k.zsh" || return
}
typeset -g __p9k_root_dir="${__p9k_root_dir:-${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k}"
source "${__p9k_root_dir}/config/p10k-lean.zsh" 2>/dev/null || source "${__p9k_root_dir}/internal/p10k.zsh" 2>/dev/null || return
POWERLEVEL9K_MODE=nerdfont-complete
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator background_jobs time)
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ ) '
EOL
        
        # Set proper ownership
        if [ "$CURRENT_USER" != "root" ]; then
            chown "$CURRENT_USER:$CURRENT_USER" "$HOME_DIR/.p10k.zsh"
        fi
        
        # Add p10k source to zshrc
        if ! grep -q '\.p10k\.zsh' "$HOME_DIR/.zshrc" 2>/dev/null; then
            if [ "$CURRENT_USER" = "root" ]; then
                echo '[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh' >> "$HOME_DIR/.zshrc"
            else
                su - "$CURRENT_USER" -c "echo '[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh' >> ~/.zshrc"
            fi
        fi
    fi
    
    # Install useful ZSH plugins
    local ZSH_CUSTOM="$HOME_DIR/.oh-my-zsh/custom"
    
    # zsh-autosuggestions
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        if [ "$CURRENT_USER" = "root" ]; then
            git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
            sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions)/g' "$HOME_DIR/.zshrc"
        else
            su - "$CURRENT_USER" -c "git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
            su - "$CURRENT_USER" -c "sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions)/g' ~/.zshrc"
        fi
    fi
    
    # zsh-syntax-highlighting (must be last plugin)
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        if [ "$CURRENT_USER" = "root" ]; then
            git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
            sed -i 's/plugins=(\(.*\))/plugins=(\1 zsh-syntax-highlighting)/g' "$HOME_DIR/.zshrc"
        else
            su - "$CURRENT_USER" -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
            su - "$CURRENT_USER" -c "sed -i 's/plugins=(\(.*\))/plugins=(\1 zsh-syntax-highlighting)/g' ~/.zshrc"
        fi
    fi
}
