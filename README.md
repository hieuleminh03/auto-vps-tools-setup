# Auto VPS Setup

Automated setup script for new VPS servers with essential development tools.

## Features

- ZSH with Oh-My-ZSH and Powerlevel10k
- Git setup with SSH key generation
- Docker and Docker Compose
- Optional development tools:
  - Node.js (via NVM)
  - Python
  - PHP
  - Java
  - Nginx
  - Certbot
  - MongoDB, PostgreSQL, Redis
  - Supervisor, PM2
  - Go, Rust
  - TensorFlow, PyTorch, Jupyter
  - CUDA Toolkit

## Requirements

- Ubuntu (18.04, 20.04, 22.04) or Debian-based Linux
- Root or sudo privileges

## Usage

```bash
git clone https://github.com/hieuleminh03/auto-vps-tools-setup
cd auto-vps-setup
chmod +x setup.sh
sudo ./setup.sh
```

## Directory Structure

```
auto-vps-setup/
├── config/               # Configuration files 
├── modules/              # Setup modules
│   ├── zsh_setup.sh
│   ├── git_setup.sh
│   ├── docker_setup.sh
│   └── optional_tools.sh
└── setup.sh              # Main script
```

## Customization

Modify module scripts directly to extend functionality.

## License

MIT License
