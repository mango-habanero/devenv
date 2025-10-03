# DevEnv

A comprehensive development environment configuration toolkit that includes shell customizations, database configurations, and automated setup scripts.

## Features

- 🐚 Customized ZSH configuration with organized modular structure
- 🐋 Ready-to-use Docker Compose templates for common databases
- ⚙️ Automated installation scripts
- 🔐 Secure secrets management
- 🚀 Starship prompt configuration

## Directory Structure

```bash
    devenv/
    ├── docs/                    # Documentation files
    ├── scripts/
    │   └── install.sh          # Installation script
    ├── templates/
    │   └── docker-compose/     # Database container templates
    │       ├── mongodb.yml
    │       ├── mysql.yml
    │       ├── postgres.yml
    │       └── redis.yml
    └── zsh/                    # ZSH configuration
        ├── custom/
        │   ├── 01-environment.zsh
        │   ├── 02-aliases.zsh
        │   ├── 03-functions.zsh
        │   └── 99-secrets.zsh.example
        ├── README.md
        └── starship.toml
```

## Installation

```bash
    git clone https://github.com/mango-habanero/devenv.git
    cd devenv
    ./scripts/install.sh
```

## Configuration

### ZSH Setup

The ZSH configuration is modular and organized in the `zsh/custom` directory:
- `01-environment.zsh`: Environment variables
- `02-aliases.zsh`: Custom aliases
- `03-functions.zsh`: Shell functions
- `99-secrets.zsh.example`: Template for sensitive configurations

### Database Templates

Launch databases using Docker Compose templates:

```bash
  docker-compose -f templates/docker-compose/postgres.yml up -d
```

Available templates:
- MongoDB
- MySQL
- PostgreSQL
- Redis

## Customization

1. Copy `99-secrets.zsh.example` to `99-secrets.zsh`
2. Modify any ZSH module in the `zsh/custom` directory
3. Adjust `starship.toml` for prompt customization

## Requirements

- Git
- ZSH
- Docker & Docker Compose
- [Starship](https://starship.rs)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License
[MIT License](./LICENSE)

## Author
[@mango-habanero](https://github.com/mango-habanero)
