#!/usr/bin/env bash
# =============================================================================
# devenv Shell Setup Script
# Purpose: One-time setup of Oh My Zsh, Starship, and zsh configuration
# Maintainer: Mango Habanero <main@mango-habanero.dev>
# =============================================================================

set -e  # Exit on error
set -u  # Exit on undefined variable

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
# Configuration
# -----------------------------------------------------------------------------
DRY_RUN=0

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
# Parse Arguments
# -----------------------------------------------------------------------------
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=1
                info "Running in DRY RUN mode - no changes will be made"
                shift
                ;;
            --help)
                print_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
}

# -----------------------------------------------------------------------------
# Print Usage
# -----------------------------------------------------------------------------
print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

One-time setup of zsh shell environment with Oh My Zsh and Starship.

Options:
    --dry-run    Show what would be done without making changes
    --help       Show this help message

This script:
    - Validates OS (Ubuntu/Debian only)
    - Checks prerequisites (zsh, git, curl)
    - Installs Oh My Zsh
    - Installs Starship prompt
    - Adds zsh to /etc/shells
    - Changes default shell to zsh

Run this script ONCE before running install.sh

EOF
}

# -----------------------------------------------------------------------------
# Validate OS
# -----------------------------------------------------------------------------
validate_os() {
    step "Validating operating system"

    if [ ! -f /etc/os-release ]; then
        error "Cannot detect OS - /etc/os-release not found"
        exit 1
    fi

    . /etc/os-release

    case "$ID" in
        ubuntu|debian|pop|linuxmint)
            success "Detected supported OS: $ID"
            ;;
        *)
            error "Unsupported OS: $ID"
            info "This script is designed for Ubuntu/Debian-based systems"
            exit 1
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Check Prerequisites
# -----------------------------------------------------------------------------
check_prerequisites() {
    step "Checking prerequisites"

    local missing=0

    # Check for zsh
    if command -v zsh >/dev/null 2>&1; then
        local zsh_version
        zsh_version=$(zsh --version 2>&1 | head -n1)
        success "zsh is installed ($zsh_version)"

        # Verify zsh is executable
        if [ ! -x "$(command -v zsh)" ]; then
            error "zsh is installed but not executable"
            missing=1
        fi
    else
        error "zsh is not installed"
        info "Install with: sudo apt install zsh"
        missing=1
    fi

    # Check for git
    if command -v git >/dev/null 2>&1; then
        local git_version
        git_version=$(git --version 2>&1 | head -n1)
        success "git is installed ($git_version)"
    else
        error "git is not installed"
        info "Install with: sudo apt install git"
        missing=1
    fi

    # Check for curl
    if command -v curl >/dev/null 2>&1; then
        success "curl is installed"
    else
        error "curl is not installed"
        info "Install with: sudo apt install curl"
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
    step "Installing Oh My Zsh"

    if [ -d "$HOME/.oh-my-zsh" ]; then
        success "Oh My Zsh is already installed"

        # Verify it's functional
        if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
            error "Oh My Zsh installation appears corrupted (missing oh-my-zsh.sh)"
            warning "Please remove $HOME/.oh-my-zsh and run this script again"
            exit 1
        fi

        return 0
    fi

    if [ $DRY_RUN -eq 1 ]; then
        info "[DRY RUN] Would install Oh My Zsh"
        return 0
    fi

    warning "Oh My Zsh is not installed"
    echo
    read -p "Install Oh My Zsh? (y/n): " -n 1 -r
    echo
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Oh My Zsh is required. Aborting setup."
        exit 1
    fi

    info "Installing Oh My Zsh..."

    # Backup existing .zshrc if it exists
    if [ -f "$HOME/.zshrc" ]; then
        BACKUP_FILE="$HOME/.zshrc.pre-omz.$(date +%s)"
        cp "$HOME/.zshrc" "$BACKUP_FILE"
        info "Backed up existing .zshrc to $BACKUP_FILE"
    fi

    # Install Oh My Zsh (unattended mode)
    if RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>&1; then
        if [ -d "$HOME/.oh-my-zsh" ] && [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
            success "Oh My Zsh installed successfully"
        else
            error "Oh My Zsh installation completed but files are missing"
            exit 1
        fi
    else
        error "Oh My Zsh installation failed"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Install Starship
# -----------------------------------------------------------------------------
install_starship() {
    step "Installing Starship"

    if command -v starship >/dev/null 2>&1; then
        local starship_version
        starship_version=$(starship --version 2>&1)
        success "Starship is already installed ($starship_version)"
        return 0
    fi

    if [ $DRY_RUN -eq 1 ]; then
        info "[DRY RUN] Would install Starship"
        return 0
    fi

    warning "Starship is not installed"
    echo
    read -p "Install Starship? (y/n): " -n 1 -r
    echo
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Starship is required. Aborting setup."
        exit 1
    fi

    info "Installing Starship..."

    # Install Starship
    if curl -sS https://starship.rs/install.sh | sh -s -- -y 2>&1; then
        # Verify installation
        if command -v starship >/dev/null 2>&1; then
            success "Starship installed successfully"
        else
            error "Starship installation completed but binary not found in PATH"
            warning "You may need to add ~/.local/bin or /usr/local/bin to your PATH"
            exit 1
        fi
    else
        error "Starship installation failed"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Ensure zsh is in /etc/shells
# -----------------------------------------------------------------------------
ensure_zsh_in_shells() {
    step "Ensuring zsh is in /etc/shells"

    local zsh_path
    zsh_path="$(command -v zsh)"

    if [ -z "$zsh_path" ]; then
        error "Could not find zsh binary"
        exit 1
    fi

    if [ ! -f /etc/shells ]; then
        error "/etc/shells does not exist"
        exit 1
    fi

    if grep -qx "$zsh_path" /etc/shells; then
        success "zsh is already in /etc/shells"
        return 0
    fi

    if [ $DRY_RUN -eq 1 ]; then
        info "[DRY RUN] Would add zsh to /etc/shells"
        return 0
    fi

    warning "zsh ($zsh_path) is not in /etc/shells"
    echo
    read -p "Add zsh to /etc/shells? (requires sudo) (y/n): " -n 1 -r
    echo
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        warning "Skipped adding zsh to /etc/shells. You may not be able to change your default shell."
        return 1
    fi

    if echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null 2>&1; then
        success "Added zsh to /etc/shells"
    else
        error "Failed to add zsh to /etc/shells"
        info "You can add it manually: echo '$zsh_path' | sudo tee -a /etc/shells"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Change Default Shell
# -----------------------------------------------------------------------------
change_default_shell() {
    step "Changing default shell to zsh"

    local current_shell
    current_shell="$(basename "$SHELL")"

    if [ "$current_shell" = "zsh" ]; then
        success "Default shell is already zsh"
        return 0
    fi

    local zsh_path
    zsh_path="$(command -v zsh)"

    if [ -z "$zsh_path" ]; then
        error "Could not find zsh binary"
        exit 1
    fi

    if [ $DRY_RUN -eq 1 ]; then
        info "[DRY RUN] Would change default shell to zsh"
        return 0
    fi

    warning "Current default shell is $current_shell"
    echo
    read -p "Change default shell to zsh? (y/n): " -n 1 -r
    echo
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        warning "Default shell not changed. You can change it later with:"
        info "  chsh -s $zsh_path"
        return 0
    fi

    info "Changing default shell to zsh..."

    if chsh -s "$zsh_path" 2>&1; then
        success "Default shell changed to zsh"
        info "Log out and log back in for the change to take full effect"
        return 0
    else
        error "Failed to change default shell"
        info "You may need to run: chsh -s $zsh_path"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Print Next Steps
# -----------------------------------------------------------------------------
print_next_steps() {
    echo
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Shell Setup Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo

    if [ $DRY_RUN -eq 1 ]; then
        echo -e "${YELLOW}This was a dry run. No changes were made.${NC}"
        echo
        return
    fi

    echo -e "${CYAN}Next Steps:${NC}"
    echo
    echo -e "  ${YELLOW}1. Run the plugins setup script:${NC}"
    echo -e "     ${BLUE}./setup-plugins.sh${NC}"
    echo
    echo -e "  ${YELLOW}2. Then install devenv configurations:${NC}"
    echo -e "     ${BLUE}./install.sh${NC}"
    echo
    echo -e "  ${YELLOW}3. Start using zsh:${NC}"
    echo -e "     ${BLUE}exec zsh${NC}"
    echo
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo
}

# -----------------------------------------------------------------------------
# Main Setup Flow
# -----------------------------------------------------------------------------
main() {
    echo -e "${CYAN}"
    cat << "EOF"
    ____
   / __ \___  _   _____  ____ _   __
  / / / / _ \| | / / _ \/ __ \ | / /
 / /_/ /  __/ |/ /  __/ / / / |/ /
/_____/\___/|___/\___/_/ /_/|___/

      Shell Setup Script
EOF
    echo -e "${NC}"

    parse_arguments "$@"
    validate_os
    check_prerequisites
    install_oh_my_zsh
    install_starship
    ensure_zsh_in_shells
    change_default_shell
    print_next_steps
}

# Run main function
main "$@"