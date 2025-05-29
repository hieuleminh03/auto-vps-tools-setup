#!/bin/bash

install_optional_tools() {
    echo "Optional Development Tools"
    
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

    # Array of available tools
    local TOOLS=(
        "NVM (Node Version Manager)"
        "Python"
        "PHP"
        "Java"
        "Nginx"
        "Certbot (Let's Encrypt)"
        "MongoDB"
        "PostgreSQL"
        "Redis"
        "Supervisor"
        "PM2"
        "Go (Golang)"
        "Rust"
        "TensorFlow Dependencies"
        "PyTorch Dependencies"
        "Jupyter Notebook"
        "CUDA Toolkit (for GPU support)"
        "Skip all optional tools"
    )

    # Function to install NVM
    install_nvm() {
        # Check if NVM is already installed
        if [ ! -d "$HOME_DIR/.nvm" ]; then
            if [ "$CURRENT_USER" = "root" ]; then
                curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
            else
                su - "$CURRENT_USER" -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash'
            fi
            
            if ! grep -q 'NVM_DIR' "$HOME_DIR/.zshrc" 2>/dev/null; then
                cat >> "$HOME_DIR/.zshrc" << 'EOL'

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOL
            fi
        fi
        
        read -p "Enter Node.js version to install (leave blank for LTS): " -r NODE_VERSION
        
        if [ -z "$NODE_VERSION" ]; then
            NODE_VERSION="--lts"
        fi
        
        if [ "$CURRENT_USER" = "root" ]; then
            source "$HOME_DIR/.nvm/nvm.sh" && nvm install $NODE_VERSION && nvm use $NODE_VERSION && nvm alias default $NODE_VERSION
            source "$HOME_DIR/.nvm/nvm.sh" && npm install -g npm yarn typescript ts-node
        else
            su - "$CURRENT_USER" -c "source ~/.nvm/nvm.sh && nvm install $NODE_VERSION && nvm use $NODE_VERSION && nvm alias default $NODE_VERSION"
            su - "$CURRENT_USER" -c "source ~/.nvm/nvm.sh && npm install -g npm yarn typescript ts-node"
        fi
    }
    
    # Function to install Python
    install_python() {
        apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev \
        libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
        xz-utils tk-dev libffi-dev liblzma-dev python3-openssl
        
        read -p "Enter Python version to install (leave blank for latest): " -r PYTHON_VERSION
        
        if [ -z "$PYTHON_VERSION" ]; then
            apt-get install -y python3 python3-pip python3-venv
        else
            apt-get install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-pip python${PYTHON_VERSION}-venv
        fi
        
        cat >> "$HOME_DIR/.zshrc" << 'EOL'

# Python aliases
alias python=python3
alias pip=pip3
EOL
        
        if [ "$CURRENT_USER" = "root" ]; then
            pip3 install --user pipenv virtualenv
        else
            su - "$CURRENT_USER" -c "pip3 install --user pipenv virtualenv"
        fi
    }
    
    # Function to install PHP
    install_php() {
        read -p "Enter PHP version to install (leave blank for latest): " -r PHP_VERSION
        
        if [ -z "$PHP_VERSION" ]; then
            apt-get install -y php php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath
        else
            apt-get install -y php$PHP_VERSION php$PHP_VERSION-cli php$PHP_VERSION-fpm php$PHP_VERSION-json php$PHP_VERSION-common php$PHP_VERSION-mysql php$PHP_VERSION-zip php$PHP_VERSION-gd php$PHP_VERSION-mbstring php$PHP_VERSION-curl php$PHP_VERSION-xml php$PHP_VERSION-pear php$PHP_VERSION-bcmath
        fi
        
        if ! command -v composer &> /dev/null; then
            EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
            php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
            ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
            
            if [ "$EXPECTED_CHECKSUM" == "$ACTUAL_CHECKSUM" ]; then
                php composer-setup.php --install-dir=/usr/local/bin --filename=composer
            fi
            rm composer-setup.php
        fi
    }
    
    # Function to install Java
    install_java() {
        echo "Available Java versions:"
        echo "1) Java 8 (LTS)"
        echo "2) Java 11 (LTS)"
        echo "3) Java 17 (LTS)"
        echo "4) Latest Java"
        
        read -p "Select Java version [1-4] (default is 3 - Java 17): " -r JAVA_CHOICE
        
        JAVA_CHOICE=${JAVA_CHOICE:-3}
        
        case $JAVA_CHOICE in
            1) apt-get install -y openjdk-8-jdk ;;
            2) apt-get install -y openjdk-11-jdk ;;
            3) apt-get install -y openjdk-17-jdk ;;
            4) apt-get install -y default-jdk ;;
            *) apt-get install -y openjdk-17-jdk ;;
        esac
        
        cat >> "$HOME_DIR/.zshrc" << 'EOL'

# Java environment
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
export PATH=$PATH:$JAVA_HOME/bin
EOL
    }
    
    # Function to install Nginx
    install_nginx() {
        apt-get install -y nginx
        systemctl start nginx
        systemctl enable nginx
    }
    
    # Function to install Certbot
    install_certbot() {
        apt-get install -y certbot python3-certbot-nginx
    }

    # Function to install MongoDB
    install_mongodb() {
        apt-get install -y gnupg
        curl -fsSL https://pgp.mongodb.com/server-6.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg
        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
        apt-get update
        apt-get install -y mongodb-org
        systemctl start mongod
        systemctl enable mongod
    }
    
    # Function to install PostgreSQL
    install_postgresql() {
        apt-get install -y postgresql postgresql-contrib
        systemctl start postgresql
        systemctl enable postgresql
        su - postgres -c "createuser --interactive --pwprompt $CURRENT_USER"
    }
    
    # Function to install Redis
    install_redis() {
        apt-get install -y redis-server
        sed -i 's/supervised no/supervised systemd/g' /etc/redis/redis.conf
        systemctl restart redis-server
        systemctl enable redis-server
    }

    # Function to install Supervisor
    install_supervisor() {
        apt-get install -y supervisor
        systemctl start supervisor
        systemctl enable supervisor
    }
    
    # Function to install PM2
    install_pm2() {
        if [ ! -d "$HOME_DIR/.nvm" ]; then
            install_nvm
        fi
        
        if [ "$CURRENT_USER" = "root" ]; then
            source "$HOME_DIR/.nvm/nvm.sh" && npm install -g pm2
            source "$HOME_DIR/.nvm/nvm.sh" && pm2 startup
        else
            su - "$CURRENT_USER" -c "source ~/.nvm/nvm.sh && npm install -g pm2"
            su - "$CURRENT_USER" -c "source ~/.nvm/nvm.sh && pm2 startup"
        fi
    }
    
    # Function to install Go (Golang)
    install_golang() {
        read -p "Enter Go version to install (leave blank for latest): " -r GO_VERSION
        
        apt-get install -y golang
        
        cat >> "$HOME_DIR/.zshrc" << 'EOL'

# Go environment
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
EOL
        
        mkdir -p "$HOME_DIR/go/"{bin,src,pkg}
        chown -R "$CURRENT_USER:$CURRENT_USER" "$HOME_DIR/go"
    }
    
    # Function to install Rust
    install_rust() {
        if [ "$CURRENT_USER" = "root" ]; then
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        else
            su - "$CURRENT_USER" -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
        fi
        
        cat >> "$HOME_DIR/.zshrc" << 'EOL'

# Rust environment
source "$HOME/.cargo/env"
EOL
    }
    
    # Function to install TensorFlow dependencies
    install_tensorflow_deps() {
        if ! command -v python3 &> /dev/null; then
            install_python
        fi
        
        apt-get install -y libhdf5-dev libc-ares-dev libeigen3-dev
        
        if [ "$CURRENT_USER" = "root" ]; then
            python3 -m venv "$HOME_DIR/ai-env"
            source "$HOME_DIR/ai-env/bin/activate" && pip install tensorflow numpy pandas scikit-learn matplotlib jupyter
        else
            su - "$CURRENT_USER" -c "python3 -m venv $HOME_DIR/ai-env"
            su - "$CURRENT_USER" -c "source $HOME_DIR/ai-env/bin/activate && pip install tensorflow numpy pandas scikit-learn matplotlib jupyter"
        fi
    }
    
    # Function to install PyTorch dependencies
    install_pytorch_deps() {
        if ! command -v python3 &> /dev/null; then
            install_python
        fi
        
        if [ ! -d "$HOME_DIR/ai-env" ]; then
            if [ "$CURRENT_USER" = "root" ]; then
                python3 -m venv "$HOME_DIR/ai-env"
            else
                su - "$CURRENT_USER" -c "python3 -m venv $HOME_DIR/ai-env"
            fi
        fi
        
        if [ "$CURRENT_USER" = "root" ]; then
            source "$HOME_DIR/ai-env/bin/activate" && pip install torch torchvision torchaudio numpy pandas scikit-learn matplotlib jupyter
        else
            su - "$CURRENT_USER" -c "source $HOME_DIR/ai-env/bin/activate && pip install torch torchvision torchaudio numpy pandas scikit-learn matplotlib jupyter"
        fi
    }
    
    # Function to install Jupyter Notebook
    install_jupyter() {
        if ! command -v python3 &> /dev/null; then
            install_python
        fi
        
        if [ "$CURRENT_USER" = "root" ]; then
            pip3 install --user jupyter notebook jupyterlab
            jupyter notebook --generate-config
        else
            su - "$CURRENT_USER" -c "pip3 install --user jupyter notebook jupyterlab"
            su - "$CURRENT_USER" -c "jupyter notebook --generate-config"
        fi
        
        JUPYTER_CONFIG="$HOME_DIR/.jupyter/jupyter_notebook_config.py"
        if [ -f "$JUPYTER_CONFIG" ]; then
            cat >> "$JUPYTER_CONFIG" << 'EOL'

# Configuration for remote access
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.open_browser = False
c.NotebookApp.port = 8888
EOL
        fi
    }
    
    # Function to install CUDA Toolkit for GPU support
    install_cuda() {
        if ! lspci | grep -i nvidia &> /dev/null; then
            echo "No NVIDIA GPU detected. CUDA may not function correctly."
            read -p "Continue with CUDA installation anyway? (y/n): " -r CONTINUE_CUDA
            if [[ ! $CONTINUE_CUDA =~ ^[Yy]$ ]]; then
                return
            fi
        fi
        
        apt-get install -y build-essential dkms
        apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
        add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/ /"
        apt-get update
        apt-get install -y cuda nvidia-cuda-toolkit
        
        cat >> "$HOME_DIR/.zshrc" << 'EOL'

# CUDA environment
export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
EOL
    }

    # Main function to display menu and handle selections
    while true; do
        echo "Optional Tools Selection"
        
        # Display menu of tools
        for i in "${!TOOLS[@]}"; do
            echo "$((i+1))) ${TOOLS[$i]}"
        done
        
        echo
        read -p "Enter the number of the tool to install (or 'q' to finish): " -r CHOICE
        
        # Exit if user is done
        if [[ "$CHOICE" == "q" || "$CHOICE" == "Q" ]]; then
            break
        fi
        
        # Skip all
        if [[ "$CHOICE" == "${#TOOLS[@]}" ]]; then
            echo "Skipping optional tools installation."
            break
        fi
        
        # Process valid selections
        if [[ "$CHOICE" =~ ^[0-9]+$ && "$CHOICE" -ge 1 && "$CHOICE" -le "${#TOOLS[@]}" ]]; then
            CHOICE=$((CHOICE-1))
            
            case "$CHOICE" in
                0) install_nvm ;;
                1) install_python ;;
                2) install_php ;;
                3) install_java ;;
                4) install_nginx ;;
                5) install_certbot ;;
                6) install_mongodb ;;
                7) install_postgresql ;;
                8) install_redis ;;
                9) install_supervisor ;;
                10) install_pm2 ;;
                11) install_golang ;;
                12) install_rust ;;
                13) install_tensorflow_deps ;;
                14) install_pytorch_deps ;;
                15) install_jupyter ;;
                16) install_cuda ;;
            esac
        else
            echo "Invalid selection. Please try again."
        fi
    done
}
