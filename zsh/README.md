# ZSH Configuration

A modular, cross-platform ZSH configuration optimized for Python (uv-first), Node.js, Docker, and Kubernetes development workflows. Features a minimal `.zshrc` with organized custom files, Starship prompt, and automatic OS detection.

> **Note**: This is a component of the larger `devenv` project. See the [root README](../README.md) for overall project context.

## Prerequisites

### Required

| Tool          | Minimum Version | Purpose          | Installation                                                                                      |
|---------------|-----------------|------------------|---------------------------------------------------------------------------------------------------|
| **zsh**       | 5.8+            | Shell            | `sudo apt install zsh` (Linux) / `brew install zsh` (macOS)                                       |
| **Oh My Zsh** | Latest          | Plugin framework | `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"` |
| **Starship**  | Latest          | Prompt           | `curl -sS https://starship.rs/install.sh \| sh`                                                   |

### Required Plugins (Manual Installation)

```bash
# zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# zsh-completions
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions
```

### Recommended (Optional)

| Tool        | Purpose                    | Installation                                                             |
|-------------|----------------------------|--------------------------------------------------------------------------|
| **uv**      | Python environment manager | `curl -LsSf https://astral.sh/uv/install.sh \| sh`                       |
| **nvm**     | Node version manager       | [nvm installation](https://github.com/nvm-sh/nvm#install--update-script) |
| **kubectl** | Kubernetes CLI             | [kubectl installation](https://kubernetes.io/docs/tasks/tools/)          |
| **docker**  | Container runtime          | [Docker installation](https://docs.docker.com/get-docker/)               |

### Operating System Compatibility

- **Linux**: Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE, Alpine (auto-detected)
- **macOS**: Full support (Homebrew detected automatically)
- **BSD**: FreeBSD, OpenBSD, NetBSD (tested)

## Quick Start

### 1. Install Prerequisites

Install required tools listed above, then verify:

```bash
zsh --version        # Should show 5.8+
omz version          # Should show Oh My Zsh installed
starship --version   # Should show version number
```

### 2. Create Symlinks

```bash
# Backup existing configurations
mv ~/.zshrc ~/.zshrc.backup 2>/dev/null
mv ~/.config/starship.toml ~/.config/starship.toml.backup 2>/dev/null

# Create symlinks (adjust paths to your devenv location)
ln -sf ~/path/to/devenv/zsh/.zshrc ~/.zshrc
ln -sf ~/path/to/devenv/zsh/custom ~/.oh-my-zsh/custom
mkdir -p ~/.config
ln -sf ~/path/to/devenv/zsh/starship.toml ~/.config/starship.toml
```

### 3. Install Required Plugins

Run the three plugin installation commands from the Prerequisites section above.

### 4. Activate Configuration

```bash
# Start a new shell or reload
exec zsh
# OR
source ~/.zshrc
```

### 5. Verify Installation

```bash
# Check prompt renders correctly
# Should show: username@hostname ~/current/directory
# With git info if in a repository

# Test aliases
gst              # Should run: git status --short --branch
ll               # Should run: ls -lahF

# Test functions
mkvenv --help    # Should show usage message
devdb postgres   # Should start PostgreSQL container (if docker installed)
```

## File Structure

```
zsh/
├── .zshrc              # Main configuration (minimal, loads custom files)
├── starship.toml       # Starship prompt configuration
├── custom/             # Oh My Zsh custom directory (symlinked to ~/.oh-my-zsh/custom)
│   ├── 01-environment.zsh    # Environment variables, PATH, tool configs
│   ├── 02-aliases.zsh        # Command aliases and small wrapper functions
│   ├── 03-functions.zsh      # Complex reusable functions (uv, docker, k8s)
│   └── 99-secrets.zsh        # Local secrets template (never commit real values)
└── README.md           # This file
```

### Loading Order & Purpose

Files are loaded in numbered order by Oh My Zsh:

| File                 | Loads When        | Purpose             | What to Add Here                                      |
|----------------------|-------------------|---------------------|-------------------------------------------------------|
| `01-environment.zsh` | Shell starts      | Environment setup   | `export` statements, PATH modifications, tool configs |
| `02-aliases.zsh`     | After environment | Quick shortcuts     | `alias` definitions, small wrapper functions          |
| `03-functions.zsh`   | After aliases     | Complex logic       | Multi-line functions, workflow helpers                |
| `99-secrets.zsh`     | Last              | Override everything | API keys, tokens, machine-specific overrides          |

### Why Minimal .zshrc?

The `.zshrc` file contains only:
- PATH initialization
- Oh My Zsh configuration
- Plugin list
- History settings
- Explicit sourcing of custom files

**All customization lives in `custom/*.zsh` files** for:
- Easier maintenance (find things quickly)
- Better version control (separate concerns)
- Selective enabling/disabling (rename `.zsh` to `.zsh.disabled`)
- Cross-machine sharing (exclude 99-secrets.zsh)

## Customization Guide

### Adding Personal Aliases

Edit `custom/02-aliases.zsh`:

```bash
# Add to the end of the file
alias myproject='cd ~/Work/MyProject && code .'
alias deploy='./scripts/deploy.sh production'
```

### Adding Custom Functions

Edit `custom/03-functions.zsh`:

```bash
# Add after existing functions
myfunction() {
  if [ -z "$1" ]; then
    echo "Usage: myfunction <argument>"
    return 1
  fi
  echo "Processing: $1"
  # Your logic here
}
```

### Adding Environment Variables

Edit `custom/01-environment.zsh`:

```bash
# Add development tool paths
export MY_TOOL_PATH="$HOME/tools/mytool"
export PATH="$MY_TOOL_PATH/bin:$PATH"

# Add API endpoints
export DEV_API_URL="https://api-dev.example.com"
```

### Adding Secrets

Edit `custom/99-secrets.zsh`:

```bash
# API keys and tokens
export GITHUB_TOKEN="ghp_your_token_here"
export OPENAI_API_KEY="sk-your_key_here"

# Database credentials (development only)
export DEV_DB_PASSWORD="your_dev_password"
```

**Important**: 
- Set strict permissions: `chmod 600 ~/.oh-my-zsh/custom/99-secrets.zsh`
- Never commit this file with real values
- Use the template version in the repository

### Creating Additional Custom Files

Add project or context-specific files:

```bash
# Create new file with appropriate number
touch ~/.oh-my-zsh/custom/04-work.zsh
touch ~/.oh-my-zsh/custom/05-personal.zsh

# Add content, then reload
source ~/.zshrc
```

### Customizing Starship Prompt

The `starship.toml` uses ASCII-safe symbols by default. To enable Nerd Font icons:

1. Install a [Nerd Font](https://www.nerdfonts.com/) (e.g., Fira Code Nerd Font)
2. Configure your terminal to use the font
3. Edit `starship.toml` and uncomment Nerd Font alternatives:

```toml
# Find sections like this:
[character]
success_symbol = "[\\$](bold green)"  # Current ASCII version

# Nerd Font alternative (uncomment if you have Nerd Fonts installed):
# success_symbol = "[➜](bold green)"
```

See [Starship documentation](https://starship.rs/config/) for detailed configuration options.

## Platform-Specific Features

### Automatic OS Detection

The configuration automatically adapts to your operating system:

| Feature         | Linux                         | macOS     | BSD        |
|-----------------|-------------------------------|-----------|------------|
| Package manager | `apt`/`dnf`/`pacman`/`zypper` | `brew`    | `pkg`      |
| Network tools   | `ss` or `netstat`             | `netstat` | `sockstat` |
| Memory info     | `free`                        | `vm_stat` | `top`      |
| CPU info        | `lscpu`                       | `sysctl`  | `sysctl`   |

### Known Platform Differences

**Linux (Default)**:
- Uses `apt` on Debian/Ubuntu (auto-detected from `/etc/os-release`)
- Uses `ss` for network port listing
- Full feature support

**macOS**:
- Uses Homebrew for package management
- Different `netstat` flags (no `-p` option)
- `vm_stat` instead of `free` command
- All features functional

**BSD**:
- Uses `pkg` package manager
- `sockstat` for port listing
- Minor command flag differences
- Core features work correctly

### Testing Cross-Platform

```bash
# Test OS detection
case "$(uname -s)" in
  Linux*)   echo "Linux detected" ;;
  Darwin*)  echo "macOS detected" ;;
  FreeBSD*) echo "FreeBSD detected" ;;
esac

# Test command availability
command -v ss >/dev/null && echo "ss available"
command -v lsof >/dev/null && echo "lsof available"
```

## Troubleshooting

### Common Issues

| Symptom                     | Cause                    | Solution                                                   |
|-----------------------------|--------------------------|------------------------------------------------------------|
| Prompt shows `>` not `$`    | Starship not initialized | Check `starship --version`, ensure it's in PATH            |
| Symbols show as boxes `□`   | Missing Nerd Font        | Install Nerd Font or use ASCII config (default)            |
| `command not found: mkvenv` | Functions not loaded     | Check `~/.oh-my-zsh/custom/03-functions.zsh` exists        |
| `gst` shows git error       | Git alias conflict       | Use `\git status` or check alias with `alias gst`          |
| Slow shell startup          | Too many plugins         | Disable unused plugins, profile with `time zsh -i -c exit` |
| Changes not appearing       | Config not reloaded      | Run `source ~/.zshrc` or `exec zsh`                        |
| Python venv not showing     | uv not detected          | Check `~/.venv` exists, verify starship Python config      |

### Debugging Steps

**1. Check file loading:**
```bash
# Add debug output to custom files
echo "Loading 01-environment.zsh"  # Add to top of file

# Reload and see output
source ~/.zshrc
```

**2. Test individual files:**
```bash
# Source files one at a time
source ~/.oh-my-zsh/custom/01-environment.zsh
source ~/.oh-my-zsh/custom/02-aliases.zsh
source ~/.oh-my-zsh/custom/03-functions.zsh
```

**3. Profile shell startup time:**
```bash
# Time full startup
time zsh -i -c exit

# Time with minimal config
zsh -f  # Start zsh without loading configs
```

**4. Check plugin status:**
```bash
# List loaded plugins
echo $plugins

# Check plugin directories
ls -la ~/.oh-my-zsh/custom/plugins/
```

**5. Verify Starship:**
```bash
# Test Starship directly
starship prompt

# Check configuration
starship config  # Shows current config path

# Measure render time
time starship prompt  # Should be < 100ms
```

### Getting Help

1. **Check file comments**: Each custom file has inline documentation
2. **Review function code**: Functions include usage messages (`mkvenv --help`)
3. **Test in isolation**: Source individual files to isolate issues
4. **Check external docs**:
   - [Oh My Zsh FAQ](https://github.com/ohmyzsh/ohmyzsh/wiki/FAQ)
   - [Starship Config](https://starship.rs/config/)
   - [ZSH Documentation](https://zsh.sourceforge.io/Doc/)

## Security Notes

### Secrets Management

- `99-secrets.zsh` is a **template only** in the repository
- Contains no real credentials
- Set to `chmod 600` automatically when sourced
- **Never commit** this file with actual secrets

### Best Practices

1. Use environment variables for secrets, not hardcoded values
2. Use separate files for work vs. personal credentials
3. Consider using a password manager (1Password, LastPass) with CLI
4. For production secrets, use proper secret management (Vault, AWS Secrets Manager)
5. Regularly audit your secrets file for unused credentials

### File Permissions

```bash
# Verify permissions
ls -la ~/.oh-my-zsh/custom/99-secrets.zsh
# Should show: -rw------- (600)

# Fix if needed
chmod 600 ~/.oh-my-zsh/custom/99-secrets.zsh
```

## Performance

### Benchmarks

Target performance metrics:

| Metric             | Target  | Acceptable | Action if Exceeded      |
|--------------------|---------|------------|-------------------------|
| Shell startup      | < 0.5s  | < 1.0s     | Disable unused plugins  |
| Prompt render      | < 50ms  | < 100ms    | Reduce Starship modules |
| Command completion | < 100ms | < 200ms    | Check completion cache  |

### Testing Performance

```bash
# Full startup time
time zsh -i -c exit

# Startup time breakdown (with profiling)
zsh -xv  # See each command as it executes

# Starship render time
time starship prompt
```

### Optimization Tips

1. **Disable unused plugins**: Comment out plugins you don't use in `.zshrc`
2. **Reduce Starship modules**: Disable language modules you don't need
3. **Use lazy loading**: Defer loading of large tools until needed
4. **Clear completion cache**: `rm -f ~/.zcompdump; compinit`

## Additional Resources

- [Oh My Zsh Documentation](https://github.com/ohmyzsh/ohmyzsh/wiki)
- [Starship Configuration](https://starship.rs/config/)
- [uv Documentation](https://docs.astral.sh/uv/)
- [ZSH Guide](https://zsh.sourceforge.io/Guide/)
- [Parent devenv project](../README.md)

## Maintenance

### Updating Components

```bash
# Update Oh My Zsh
omz update

# Update Starship
curl -sS https://starship.rs/install.sh | sh

# Update plugins (manual - cd into each and git pull)
cd ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions && git pull
cd ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && git pull
cd ~/.oh-my-zsh/custom/plugins/zsh-completions && git pull
```

### Testing Changes

Before committing changes:

1. Test in a clean shell: `zsh -f`
2. Source files individually to test
3. Verify on different OS if possible
4. Check performance hasn't degraded
5. Ensure no errors in startup

---

**Last Updated**: 2025-10-03  
**Maintainer**: Mango Habanero <main@mango-habanero.dev>  
**License**: MIT