# DevEnv

A comprehensive development environment configuration toolkit that includes shell customizations, database configurations, and automated setup scripts following SOLID principles.

## Features

- 🐚 Customized ZSH configuration with organized modular structure
- 🔌 Modular installation scripts (shell setup, plugins, configurations)
- 🐋 Ready-to-use Docker Compose templates for common databases
- 🔐 Secure secrets management
- 🚀 Starship prompt configuration
- 🧹 Clean uninstallation with backup restoration
- 📁 Copy-based installation (portable, no symlinks)

## Directory Structure

```bash
devenv/
├── docs/                    # Documentation files
├── scripts/
│   ├── setup-shell.sh      # One-time shell setup (Oh My Zsh, Starship)
│   ├── setup-plugins.sh    # ZSH plugins installation
│   ├── install.sh          # devenv configuration installation
│   └── cleanup.sh          # Uninstall devenv configurations
├── templates/
│   └── docker-compose/     # Database container templates
│       ├── mongodb.yml
│       ├── mysql.yml
│       ├── postgres.yml
│       └── redis.yml
└── zsh/                    # ZSH configuration
    ├── .zshrc              # Main ZSH configuration file
    ├── custom/
    │   ├── 01-environment.zsh
    │   ├── 02-aliases.zsh
    │   ├── 03-functions.zsh
    │   └── 99-secrets.zsh.example
    ├── starship.toml
    └── README.md
```

## Prerequisites

- **Operating System**: Ubuntu/Debian-based Linux distribution
- **Required packages**: zsh, git, curl
  ```bash
  sudo apt install zsh git curl
  ```

## Installation

### Quick Start

```bash
# Clone the repository
git clone https://github.com/mango-habanero/devenv.git
cd devenv/scripts

# 1. Set up shell environment (one-time)
./setup-shell.sh

# 2. Install ZSH plugins
./setup-plugins.sh

# 3. Install devenv configurations
./install.sh

# 4. Start using your new shell
exec zsh
```

### Installation Steps Explained

#### Step 1: Shell Setup (One-time)
```bash
./setup-shell.sh
```
This script:
- Validates your OS (Ubuntu/Debian only)
- Checks prerequisites (zsh, git, curl)
- Installs Oh My Zsh
- Installs Starship prompt
- Adds zsh to /etc/shells
- Changes your default shell to zsh

**Options:**
- `--dry-run` - Preview what would be installed without making changes
- `--help` - Display usage information

#### Step 2: Plugin Setup
```bash
./setup-plugins.sh
```
This script installs essential ZSH plugins:
- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-completions

Plugins are installed to `~/.oh-my-zsh/custom/plugins/`

**Note:** This script can be re-run to add new plugins as they're added to the list.

**Options:**
- `--dry-run` - Preview what would be installed
- `--help` - Display usage information

#### Step 3: Configuration Installation
```bash
./install.sh
```
This script:
- Validates devenv directory structure
- Prompts to backup existing configurations
- Copies `.zshrc` to `~/.zshrc`
- Copies `starship.toml` to `~/.config/starship.toml`
- Copies custom ZSH files to `~/.oh-my-zsh/custom/`
- Creates `99-secrets.zsh` from template (if it doesn't exist)
- Verifies installation

**Options:**
- `--dry-run` - Preview what would be copied
- `--help` - Display usage information

**Important:** This script can be re-run whenever you want to update your configurations from the devenv repository.

## Updating Configurations

When you update the devenv repository and want to apply changes:

```bash
cd devenv/scripts
./install.sh
```

The script will:
1. Ask if you want to backup existing configs
2. Copy updated files to your home directory
3. Preserve your `99-secrets.zsh` file

## Uninstallation

To remove devenv configurations and restore backups:

```bash
cd devenv/scripts
./cleanup.sh
```

This script:
- Removes devenv configuration files (`.zshrc`, `starship.toml`, custom files)
- Asks about removing your secrets file (backs it up if removed)
- Restores from backups if available
- Optionally resets your default shell to bash

**Note:** This does NOT remove Oh My Zsh, Starship, or plugins. It only removes devenv-specific configurations.

## Configuration

### ZSH Modules

After installation, your ZSH configuration lives in `~/.zshrc` and sources files from `~/.oh-my-zsh/custom/`:

- `01-environment.zsh`: Environment variables and PATH modifications
- `02-aliases.zsh`: Custom command aliases
- `03-functions.zsh`: Reusable shell functions
- `99-secrets.zsh`: Your API keys, tokens, and secrets (never committed)

**Editing configurations:**
You can edit these files directly in your home directory:
```bash
nano ~/.oh-my-zsh/custom/02-aliases.zsh
exec zsh  # Reload to apply changes
```

Or edit them in the devenv repo and re-run `./install.sh` to update.

### Secrets Management

1. After installation, edit your secrets file:
   ```bash
   nano ~/.oh-my-zsh/custom/99-secrets.zsh
   ```

2. Add your sensitive environment variables:
   ```bash
   export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
   export OPENAI_API_KEY="sk-xxxxxxxxxxxx"
   export AWS_ACCESS_KEY_ID="xxxxxxxxxxxx"
   ```

3. This file is never overwritten by `install.sh` updates

### Starship Prompt

Customize your prompt by editing:
```bash
nano ~/.config/starship.toml
```

See [Starship documentation](https://starship.rs/config/) for configuration options.

## Database Templates

Launch databases using Docker Compose templates:

```bash
# PostgreSQL
docker-compose -f templates/docker-compose/postgres.yml up -d

# MongoDB
docker-compose -f templates/docker-compose/mongodb.yml up -d

# MySQL
docker-compose -f templates/docker-compose/mysql.yml up -d

# Redis
docker-compose -f templates/docker-compose/redis.yml up -d
```

## Troubleshooting

### "exec zsh" doesn't work
```bash
# Use full path to zsh
/usr/bin/zsh

# Or check where zsh is installed
which zsh
```

### Permission denied errors
```bash
# Fix permissions on custom files
chmod 644 ~/.oh-my-zsh/custom/*.zsh
```

### Configuration not loading
```bash
# Test for syntax errors
zsh -n ~/.zshrc

# Test loading
zsh -c "source ~/.zshrc"
```

### Plugins not working
```bash
# Verify plugins are installed
ls -la ~/.oh-my-zsh/custom/plugins/

# Re-run plugin setup if needed
cd devenv/scripts
./setup-plugins.sh
```

## Architecture

This project follows SOLID principles with clear separation of concerns:

- **setup-shell.sh**: Handles shell environment setup (Oh My Zsh, Starship)
- **setup-plugins.sh**: Manages ZSH plugins independently
- **install.sh**: Installs devenv configurations (repeatable for updates)
- **cleanup.sh**: Removes installations and restores backups

Configurations are **copied** to your home directory (not symlinked), making them:
- Portable (devenv can be moved or deleted)
- User-editable (modify directly in home directory)
- Version-controlled (track both repo and local changes)

## Requirements

- **Operating System**: Ubuntu, Debian, Pop!_OS, or Linux Mint
- **Shell**: ZSH (installed via setup-shell.sh)
- **Version Control**: Git
- **Network Tool**: curl
- **Optional**: Docker & Docker Compose (for database templates)

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test with `--dry-run` flags
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

[MIT License](./LICENSE.md)

## Author

[@mango-habanero](https://github.com/mango-habanero)

## Acknowledgments

- [Oh My Zsh](https://ohmyz.sh/) - ZSH framework
- [Starship](https://starship.rs/) - Cross-shell prompt
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [zsh-completions](https://github.com/zsh-users/zsh-completions)