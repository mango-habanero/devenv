#!/usr/bin/env bash
# =============================================================================
# devenv Installation Script
# Purpose: Automated setup of ZSH configuration with Oh My Zsh and Starship
# Maintainer: Mango Habanero <main@mango-habanero.dev>
# =============================================================================

set -e  # Exit on error

# -----------------------------------------------------------------------------
# Color Codes for Output
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Output Functions
# -----------------------------------------------------------------------------
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
}

step() {
    echo -e "\n${CYAN}==>${NC} $1"
}

# -----------------------------------------------------------------------------
# Detect Operating System
# -----------------------------------------------------------------------------
detect_os() {
    case "$(uname -s)" in
        Linux*)
            OS="linux"
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                DISTRO="$ID"
            else
                DISTRO="unknown"
            fi
            ;;
        Darwin*)
            OS="macos"
            DISTRO="macos"
            ;;
        FreeBSD*)
            OS="freebsd"
            DISTRO="freebsd"
            ;;
        OpenBSD*)
            OS="openbsd"
            DISTRO="openbsd"
            ;;
        *)
            OS="unknown"
            DISTRO="unknown"
            ;;
    esac

    info "Detected OS: $OS ($DISTRO)"
}

# -----------------------------------------------------------------------------
# Get Script Directory
# -----------------------------------------------------------------------------
get_script_dir() {
    # Works on both Linux and macOS
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    DEVENV_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
    info "devenv directory: $DEVENV_DIR"
}

# -----------------------------------------------------------------------------
# Check Prerequisites
# -----------------------------------------------------------------------------
check_prerequisites() {
    step "Checking prerequisites"

    local missing=0

    # Check for zsh
    if command -v zsh >/dev/null 2>&1; then
        success "zsh is installed ($(zsh --version | head -n1))"
    else
        error "zsh is not installed"
        case "$DISTRO" in
            ubuntu|debian|pop|linuxmint)
                info "Install with: sudo apt install zsh"
                ;;
            fedora|rhel|centos|rocky|almalinux)
                info "Install with: sudo dnf install zsh"
                ;;
            arch|manjaro|endeavouros)
                info "Install with: sudo pacman -S zsh"
                ;;
            macos)
                info "Install with: brew install zsh"
                ;;
            freebsd|openbsd)
                info "Install with: sudo pkg install zsh"
                ;;
        esac
        missing=1
    fi

    # Check for git
    if command -v git >/dev/null 2>&1; then
        success "git is installed ($(git --version | head -n1))"
    else
        error "git is not installed"
        case "$DISTRO" in
            ubuntu|debian|pop|linuxmint)
                info "Install with: sudo apt install git"
                ;;
            fedora|rhel|centos|rocky|almalinux)
                info "Install with: sudo dnf install git"
                ;;
            arch|manjaro|endeavouros)
                info "Install with: sudo pacman -S git"
                ;;
            macos)
                info "Install with: brew install git"
                ;;
            freebsd|openbsd)
                info "Install with: sudo pkg install git"
                ;;
        esac
        missing=1
    fi

    # Check for curl
    if command -v curl >/dev/null 2>&1; then
        success "curl is installed"
    else
        error "curl is not installed"
        case "$DISTRO" in
            ubuntu|debian|pop|linuxmint)
                info "Install with: sudo apt install curl"
                ;;
            fedora|rhel|centos|rocky|almalinux)
                info "Install with: sudo dnf install curl"
                ;;
            arch|manjaro|endeavouros)
                info "Install with: sudo pacman -S curl"
                ;;
            macos)
                info "curl should be pre-installed"
                ;;
            freebsd|openbsd)
                info "Install with: sudo pkg install curl"
                ;;
        esac
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        error "Missing required prerequisites. Please install them and run this script again."
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Install Oh My Zsh
# -----------------------------------------------------------------------------
install_oh_my_zsh() {
    step "Checking Oh My Zsh installation"

    if [ -d "$HOME/.oh-my-zsh" ]; then
        success "Oh My Zsh is already installed"
        return 0
    fi

    warning "Oh My Zsh is not installed"
    read -p "Install Oh My Zsh? (y/n): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Oh My Zsh is required. Aborting installation."
        exit 1
    fi

    info "Installing Oh My Zsh..."

    # Backup existing .zshrc if it exists
    if [ -f "$HOME/.zshrc" ]; then
        BACKUP_FILE="$HOME/.zshrc.pre-omz.$(date +%s)"
        mv "$HOME/.zshrc" "$BACKUP_FILE"
        info "Backed up existing .zshrc to $BACKUP_FILE"
    fi

    # Install Oh My Zsh (unattended mode)
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    if [ -d "$HOME/.oh-my-zsh" ]; then
        success "Oh My Zsh installed successfully"
    else
        error "Oh My Zsh installation failed"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Install Starship
# -----------------------------------------------------------------------------
install_starship() {
    step "Checking Starship installation"

    if command -v starship >/dev/null 2>&1; then
        success "Starship is already installed ($(starship --version))"
        return 0
    fi

    warning "Starship is not installed"
    read -p "Install Starship? (y/n): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Starship is required. Aborting installation."
        exit 1
    fi

    info "Installing Starship..."

    # Install Starship
    curl -sS https://starship.rs/install.sh | sh -s -- -y

    if command -v starship >/dev/null 2>&1; then
        success "Starship installed successfully"
    else
        error "Starship installation failed"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Backup Existing Configurations
# -----------------------------------------------------------------------------
backup_existing_configs() {
    step "Backing up existing configurations"

    local timestamp
    timestamp=$(date +%s)
    local backed_up=0

    # Backup .zshrc
    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        BACKUP_FILE="$HOME/.zshrc.backup.$timestamp"
        cp "$HOME/.zshrc" "$BACKUP_FILE"
        info "Backed up .zshrc to $BACKUP_FILE"
        backed_up=1
    fi

    # Backup starship.toml
    if [ -f "$HOME/.config/starship.toml" ] && [ ! -L "$HOME/.config/starship.toml" ]; then
        BACKUP_FILE="$HOME/.config/starship.toml.backup.$timestamp"
        cp "$HOME/.config/starship.toml" "$BACKUP_FILE"
        info "Backed up starship.toml to $BACKUP_FILE"
        backed_up=1
    fi

    # Backup Oh My Zsh custom directory
    if [ -d "$HOME/.oh-my-zsh/custom" ] && [ ! -L "$HOME/.oh-my-zsh/custom" ]; then
        BACKUP_DIR="$HOME/.oh-my-zsh/custom.backup.$timestamp"
        cp -r "$HOME/.oh-my-zsh/custom" "$BACKUP_DIR"
        info "Backed up custom directory to $BACKUP_DIR"
        backed_up=1
    fi

    if [ "$backed_up" -eq 0 ]; then
        info "No existing configurations to backup"
    else
        success "Backups completed"
    fi
}

# -----------------------------------------------------------------------------
# Create Symlinks
# -----------------------------------------------------------------------------
create_symlinks() {
    step "Creating symlinks"

    # Remove existing symlinks or files
    [ -L "$HOME/.zshrc" ] && rm "$HOME/.zshrc"
    [ -f "$HOME/.zshrc" ] && rm "$HOME/.zshrc"

    [ -L "$HOME/.config/starship.toml" ] && rm "$HOME/.config/starship.toml"
    [ -f "$HOME/.config/starship.toml" ] && rm "$HOME/.config/starship.toml"

    [ -L "$HOME/.oh-my-zsh/custom" ] && rm "$HOME/.oh-my-zsh/custom"
    [ -d "$HOME/.oh-my-zsh/custom" ] && rm -rf "$HOME/.oh-my-zsh/custom"

    # Create .config directory if it doesn't exist
    mkdir -p "$HOME/.config"

    # Create symlinks
    ln -sf "$DEVENV_DIR/zsh/.zshrc" "$HOME/.zshrc"
    success "Linked .zshrc"

    ln -sf "$DEVENV_DIR/zsh/starship.toml" "$HOME/.config/starship.toml"
    success "Linked starship.toml"

    ln -sf "$DEVENV_DIR/zsh/custom" "$HOME/.oh-my-zsh/custom"
    success "Linked custom directory"
}

# -----------------------------------------------------------------------------
# Install Required Plugins
# -----------------------------------------------------------------------------
install_plugins() {
    step "Installing required Oh My Zsh plugins"

    local CUSTOM_PLUGINS="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

    # zsh-autosuggestions
    if [ -d "$CUSTOM_PLUGINS/zsh-autosuggestions" ]; then
        info "zsh-autosuggestions already installed"
    else
        info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$CUSTOM_PLUGINS/zsh-autosuggestions"
        success "zsh-autosuggestions installed"
    fi

    # zsh-syntax-highlighting
    if [ -d "$CUSTOM_PLUGINS/zsh-syntax-highlighting" ]; then
        info "zsh-syntax-highlighting already installed"
    else
        info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$CUSTOM_PLUGINS/zsh-syntax-highlighting"
        success "zsh-syntax-highlighting installed"
    fi

    # zsh-completions
    if [ -d "$CUSTOM_PLUGINS/zsh-completions" ]; then
        info "zsh-completions already installed"
    else
        info "Installing zsh-completions..."
        git clone https://github.com/zsh-users/zsh-completions "$CUSTOM_PLUGINS/zsh-completions"
        success "zsh-completions installed"
    fi
}

# -----------------------------------------------------------------------------
# Create Secrets Template
# -----------------------------------------------------------------------------
create_secrets_template() {
    step "Setting up secrets file"

    local SECRETS_FILE="$HOME/.oh-my-zsh/custom/99-secrets.zsh"

    if [ -f "$SECRETS_FILE" ]; then
        info "Secrets file already exists at $SECRETS_FILE"
    else
        info "Creating secrets file from template..."
        cp "$DEVENV_DIR/zsh/custom/99-secrets.zsh.example" "$SECRETS_FILE" 2>/dev/null || {
            # If example doesn't exist, create a minimal one
            cat > "$SECRETS_FILE" << 'EOF'
# -----------------------------------------------------------------------------
# Local Secrets - NEVER commit this file with real values
# -----------------------------------------------------------------------------

# Example:
# export GITHUB_TOKEN="your_token_here"
# export OPENAI_API_KEY="your_key_here"

EOF
        }
        chmod 600 "$SECRETS_FILE"
        success "Created secrets file (remember to add your actual secrets)"
    fi
}

# -----------------------------------------------------------------------------
# Verify Installation
# -----------------------------------------------------------------------------
verify_installation() {
    step "Verifying installation"

    # Check symlinks exist
    if [ -L "$HOME/.zshrc" ] && [ -L "$HOME/.config/starship.toml" ] && [ -L "$HOME/.oh-my-zsh/custom" ]; then
        success "All symlinks created successfully"
    else
        error "Some symlinks are missing"
        return 1
    fi

    # Check plugins exist
    local CUSTOM_PLUGINS="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    if [ -d "$CUSTOM_PLUGINS/zsh-autosuggestions" ] && \
       [ -d "$CUSTOM_PLUGINS/zsh-syntax-highlighting" ] && \
       [ -d "$CUSTOM_PLUGINS/zsh-completions" ]; then
        success "All required plugins installed"
    else
        error "Some plugins are missing"
        return 1
    fi

    # Test zsh configuration syntax
    if zsh -n "$HOME/.zshrc" 2>/dev/null; then
        success "ZSH configuration syntax is valid"
    else
        warning "ZSH configuration has syntax issues (may still work)"
    fi

    success "Installation verification complete"
}

# -----------------------------------------------------------------------------
# Print Next Steps
# -----------------------------------------------------------------------------
print_next_steps() {
    echo
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${CYAN}Next Steps:${NC}"
    echo
    echo -e "  1. ${YELLOW}Activate your new shell:${NC}"
    echo -e "     ${BLUE}exec zsh${NC}"
    echo
    echo -e "  2. ${YELLOW}Or reload configuration:${NC}"
    echo -e "     ${BLUE}source ~/.zshrc${NC}"
    echo
    echo -e "  3. ${YELLOW}Add your secrets:${NC}"
    echo -e "     ${BLUE}nano ~/.oh-my-zsh/custom/99-secrets.zsh${NC}"
    echo
    echo -e "  4. ${YELLOW}Read the documentation:${NC}"
    echo -e "     ${BLUE}cat $DEVENV_DIR/zsh/README.md${NC}"
    echo
    echo -e "${CYAN}Optional Tools to Install:${NC}"
    echo
    echo -e "  • ${YELLOW}uv${NC} (Python): ${BLUE}curl -LsSf https://astral.sh/uv/install.sh | sh${NC}"
    echo -e "  • ${YELLOW}nvm${NC} (Node): ${BLUE}See https://github.com/nvm-sh/nvm#install--update-script${NC}"
    echo
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo
}

# -----------------------------------------------------------------------------
# Main Installation Flow
# -----------------------------------------------------------------------------
main() {
    echo -e "${CYAN}"
    cat << "EOF"
    ____
   / __ \___  _   _____  ____ _   __
  / / / / _ \| | / / _ \/ __ \ | / /
 / /_/ /  __/ |/ /  __/ / / / |/ /
/_____/\___/|___/\___/_/ /_/|___/

        Installation Script
EOF
    echo -e "${NC}"

    detect_os
    get_script_dir
    check_prerequisites
    install_oh_my_zsh
    install_starship
    backup_existing_configs
    create_symlinks
    install_plugins
    create_secrets_template
    verify_installation
    print_next_steps
}

# Run main function
main "$@"