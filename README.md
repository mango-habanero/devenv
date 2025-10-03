# devenv

A modular, cross-platform development environment configuration focused on Python (uv), Node.js, Docker, and Kubernetes workflows. Built for reliability, portability, and developer productivity.

## What's Inside

**Shell Configuration** ([zsh/](zsh/))
- Minimal `.zshrc` with modular custom files
- Starship prompt (fast, cross-platform)
- Oh My Zsh with essential plugins
- 200+ aliases and functions for daily workflows
- uv-first Python environment management
- Automatic OS detection (Linux, macOS, BSD)

**Development Templates** ([templates/](templates/))
- Docker Compose files for PostgreSQL, Redis, MySQL, MongoDB
- Full-stack development environment (Postgres + Redis)
- Modern Compose Specification with health checks

**Installation Automation** ([scripts/](scripts/))
- One-command setup script
- Cross-platform support
- Automatic prerequisite installation
- Safe backups of existing configurations

## Quick Start

### Prerequisites

- **zsh** (5.8+)
- **git**
- **curl**

Optional but recommended: [uv](https://docs.astral.sh/uv/), [docker](https://docs.docker.com/get-docker/), [kubectl](https://kubernetes.io/docs/tasks/tools/)

### Installation

```bash
    # Clone the repository
    git clone https://github.com/yourusername/devenv.git ~/devenv
    cd ~/devenv
    
    # Run the installation script
    chmod +x scripts/install.sh
    ./scripts/install.sh
    
    # Activate your new configuration
    exec zsh
```

The installation script will:
1. Check for required tools (installs Oh My Zsh and Starship if missing)
2. Backup your existing configurations
3. Create symlinks to devenv files
4. Install required Oh My Zsh plugins
5. Set up secrets template

### What Gets Installed

After installation:
- `~/.zshrc` → symlinked to `devenv/zsh/.zshrc`
- `~/.config/starship.toml` → symlinked to `devenv/zsh/starship.toml`
- `~/.oh-my-zsh/custom/` → symlinked to `devenv/zsh/custom/`

Your existing configurations are backed up with timestamps (e.g., `.zshrc.backup.1234567890`).

## Repository Structure

```
devenv/
├── zsh/                          # Shell configuration
│   ├── .zshrc                    # Main ZSH config (minimal)
│   ├── starship.toml             # Starship prompt config
│   ├── custom/                   # Modular configuration files
│   │   ├── 01-environment.zsh    # Environment variables
│   │   ├── 02-aliases.zsh        # Command aliases
│   │   ├── 03-functions.zsh      # Reusable functions
│   │   └── 99-secrets.zsh        # Local secrets (not committed)
│   └── README.md                 # Detailed ZSH documentation
├── templates/                    # Project scaffolds and configs
│   └── docker-compose/           # Development databases
│       ├── postgres.yml          # PostgreSQL 17
│       ├── redis.yml             # Redis 7
│       ├── mysql.yml             # MySQL 9
│       ├── mongodb.yml           # MongoDB 8
│       ├── fullstack.yml         # Complete backend stack
│       └── README.md             # Docker Compose guide
├── scripts/                      # Automation scripts
│   └── install.sh                # Main installation script
├── docs/                         # Additional documentation
├── .gitignore                    # Git exclusions
└── README.md                     # This file
```

## Key Features

### Cross-Platform Compatibility

Automatically adapts to your operating system:
- **Linux**: Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE, Alpine
- **macOS**: Full support with Homebrew integration
- **BSD**: FreeBSD, OpenBSD, NetBSD

Package manager commands, network tools, and system utilities adjust automatically based on detected OS.

### Modular Configuration

Instead of one large config file, settings are organized by purpose:

| File                 | Purpose               | Examples                      |
|----------------------|-----------------------|-------------------------------|
| `01-environment.zsh` | Environment variables | PATH, EDITOR, tool configs    |
| `02-aliases.zsh`     | Command shortcuts     | `gst`, `ll`, `k` (kubectl)    |
| `03-functions.zsh`   | Complex workflows     | `mkvenv`, `devdb`, `kswitch`  |
| `99-secrets.zsh`     | Sensitive data        | API keys, tokens (local only) |

Benefits:
- Easy to find and modify settings
- Selective enabling/disabling (rename to `.disabled`)
- Clear separation of concerns
- Version control friendly

### Development Workflow Tools

**Git workflows:**
```text
    gst              # Short git status
    gco main         # Switch branches
    gpr              # Pull with rebase
    gpf              # Force push with lease (safer)
    glog             # Pretty git log
```

**Python with uv:**
```text
mkvenv .venv     # Create virtual environment
activate         # Activate local venv
pyproject myapp  # Scaffold new Python project
```

**Docker:**
```bash
    devdb postgres   # Start development database
    stopdb postgres  # Stop and remove database
    dps              # Pretty docker ps output
```

**Kubernetes:**
```bash
    k get pods       # kubectl shorthand
    kswitch dev      # Switch contexts
    klogs mypod      # Follow pod logs
    ksh mypod        # Exec into pod
```

### Development Databases

Pre-configured Docker Compose files with:
- Health checks for reliable startup
- Named volumes for data persistence
- Resource limits suitable for development
- Clear connection documentation

```bash
    # Start PostgreSQL
    docker compose -f templates/docker-compose/postgres.yml up -d
    
    # Or use the shell function
    devdb postgres
```

See [templates/docker-compose/README.md](templates/docker-compose/README.md) for details.

## Customization

### Adding Personal Aliases

Edit `~/.oh-my-zsh/custom/02-aliases.zsh`:

```bash
  alias myproject='cd ~/Work/MyProject && code .'
```

### Adding Functions

Edit `~/.oh-my-zsh/custom/03-functions.zsh`:

```bash
    myfunction() {
      echo "Your logic here"
    }
```

### Adding Secrets

Edit `~/.oh-my-zsh/custom/99-secrets.zsh`:

```bash
    export GITHUB_TOKEN="your_token_here"
    export OPENAI_API_KEY="your_key_here"
```

**Important**: This file has strict permissions (`chmod 600`) and is excluded from git.

### Customizing Starship Prompt

Edit `~/.config/starship.toml` to modify your prompt appearance. See [Starship documentation](https://starship.rs/config/) for options.

To enable Nerd Font icons:
1. Install a [Nerd Font](https://www.nerdfonts.com/)
2. Configure your terminal to use it
3. Uncomment Nerd Font alternatives in `starship.toml`

## Documentation

- **[zsh/README.md](zsh/README.md)** - Comprehensive ZSH configuration guide
- **[templates/docker-compose/README.md](templates/docker-compose/README.md)** - Docker Compose template usage
- **[scripts/install.sh](scripts/install.sh)** - Installation script (self-documented)

## Updating

### Update Oh My Zsh
```bash
    omz update
```

### Update Starship
```bash
    curl -sS https://starship.rs/install.sh | sh
```

### Update Plugins
```bash
    cd ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions && git pull
    cd ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && git pull
    cd ~/.oh-my-zsh/custom/plugins/zsh-completions && git pull
```

### Update devenv
```bash
    cd ~/devenv
    git pull
```

Symlinks automatically reflect changes - no need to reinstall.

## Uninstallation

### Remove Symlinks

```bash
    rm ~/.zshrc
    rm ~/.config/starship.toml
    rm ~/.oh-my-zsh/custom
```

### Restore Backups

```bash
    # Find your backup
    ls -la ~/ | grep .zshrc.backup
    
    # Restore it
    mv ~/.zshrc.backup.TIMESTAMP ~/.zshrc
```

### Clean Up

```bash
    # Remove repository
    rm -rf ~/devenv

    # Optional: Remove Oh My Zsh
    uninstall_oh_my_zsh
```

## Troubleshooting

### Slow Shell Startup

```bash
    # Time startup
    time zsh -i -c exit
    
    # If > 1 second, check plugins
    # Disable unused plugins in ~/.zshrc
    ```
    
    ### Commands Not Found
    
    ```bash
    # Check if functions loaded
    type mkvenv
    type devdb
    
    # Reload configuration
    source ~/.zshrc
```

### Prompt Not Showing

```bash
    # Check Starship installed
    starship --version
    
    # Check Starship initialized
    grep starship ~/.zshrc
```

See [zsh/README.md](zsh/README.md) for detailed troubleshooting.

## Requirements

### Required
- zsh 5.8+
- git
- curl

### Installed by Script
- Oh My Zsh
- Starship
- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-completions

### Optional but Recommended
- [uv](https://docs.astral.sh/uv/) - Python package manager
- [nvm](https://github.com/nvm-sh/nvm) - Node version manager
- [docker](https://docs.docker.com/get-docker/) - Container runtime
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI

## Contributing

This is a personal development environment, but suggestions and improvements are welcome:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on a clean system
5. Submit a pull request

Please ensure:
- Cross-platform compatibility (test on Linux and macOS if possible)
- Clear documentation
- No secrets committed (check with `git diff` before committing)

## Security

### Secrets Management

- **Never commit** real secrets to this repository
- Use `99-secrets.zsh` for local credentials only
- Keep `99-secrets.zsh` at `chmod 600` permissions
- Consider using a password manager (1Password, LastPass) with CLI integration

### Reporting Issues

If you find security vulnerabilities, please report them privately:
- Email: main@mango-habanero.dev
- Do not create public issues for security concerns

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

Built with:
- [Oh My Zsh](https://ohmyz.sh/) - ZSH framework
- [Starship](https://starship.rs/) - Cross-shell prompt
- [uv](https://docs.astral.sh/uv/) - Python package management

Inspired by the dotfiles community and countless developers sharing their configurations.

---

**Maintainer**: Mango Habanero  
**Contact**: main@mango-habanero.dev  
**Repository**: [github.com/mango-habanero/devenv](https://github.com/mango-habanero/devenv)  
**Last Updated**: 2025-10-03