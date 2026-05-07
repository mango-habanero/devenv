#!/usr/bin/env bash
# =============================================================================
# devenv Cleanup Script
# Purpose: Remove devenv installation and restore to pre-installation state
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
# Check What's Installed
# -----------------------------------------------------------------------------
check_installation() {
    step "Checking what's installed"

    local found_items=0

    # Check for .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        info "Found .zshrc"
        found_items=1
    fi

    # Check for starship.toml
    if [ -f "$HOME/.config/starship.toml" ]; then
        info "Found starship.toml"
        found_items=1
    fi

    # Check for custom files
    if [ -d "$HOME/.oh-my-zsh/custom" ]; then
        if [ -f "$HOME/.oh-my-zsh/custom/01-environment.zsh" ] || \
           [ -f "$HOME/.oh-my-zsh/custom/02-aliases.zsh" ] || \
           [ -f "$HOME/.oh-my-zsh/custom/03-functions.zsh" ]; then
            info "Found devenv custom files"
            found_items=1
        fi
    fi

    # Check for secrets file
    if [ -f "$HOME/.oh-my-zsh/custom/99-secrets.zsh" ]; then
        info "Found secrets file"
        found_items=1
    fi

    if [ $found_items -eq 0 ]; then
        success "No devenv installation found"
        exit 0
    fi

    echo
}

# -----------------------------------------------------------------------------
# Confirm Cleanup
# -----------------------------------------------------------------------------
confirm_cleanup() {
    warning "This will remove your devenv configuration files"
    echo
    read -p "Do you want to continue? (y/n): " -n 1 -r
    echo
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Cleanup cancelled"
        exit 0
    fi
}

# -----------------------------------------------------------------------------
# Find Latest Backup
# -----------------------------------------------------------------------------
find_latest_backup() {
    local pattern=$1
    local latest=""

    shopt -s nullglob
    for file in "$pattern"*; do
        if [ -f "$file" ] || [ -d "$file" ]; then
            if [ -z "$latest" ] || [ "$file" -nt "$latest" ]; then
                latest=$file
            fi
        fi
    done
    shopt -u nullglob

    echo "$latest"
}

# -----------------------------------------------------------------------------
# Remove Devenv Files
# -----------------------------------------------------------------------------
remove_devenv_files() {
    step "Removing devenv configuration files"

    local removed=0

    # Remove .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        rm "$HOME/.zshrc"
        success "Removed .zshrc"
        removed=1
    fi

    # Remove starship.toml
    if [ -f "$HOME/.config/starship.toml" ]; then
        rm "$HOME/.config/starship.toml"
        success "Removed starship.toml"
        removed=1
    fi

    # Remove custom files (but not the whole directory - plugins might be there)
    if [ -d "$HOME/.oh-my-zsh/custom" ]; then
        local custom_files_removed=0

        if [ -f "$HOME/.oh-my-zsh/custom/01-environment.zsh" ]; then
            rm "$HOME/.oh-my-zsh/custom/01-environment.zsh"
            success "Removed 01-environment.zsh"
            custom_files_removed=1
        fi

        if [ -f "$HOME/.oh-my-zsh/custom/02-aliases.zsh" ]; then
            rm "$HOME/.oh-my-zsh/custom/02-aliases.zsh"
            success "Removed 02-aliases.zsh"
            custom_files_removed=1
        fi

        if [ -f "$HOME/.oh-my-zsh/custom/03-functions.zsh" ]; then
            rm "$HOME/.oh-my-zsh/custom/03-functions.zsh"
            success "Removed 03-functions.zsh"
            custom_files_removed=1
        fi

        if [ $custom_files_removed -eq 1 ]; then
            removed=1
        fi
    fi

    if [ $removed -eq 0 ]; then
        info "No devenv files found to remove"
    fi
}

# -----------------------------------------------------------------------------
# Handle Secrets File
# -----------------------------------------------------------------------------
handle_secrets() {
    step "Handling secrets file"

    local SECRETS_FILE="$HOME/.oh-my-zsh/custom/99-secrets.zsh"

    if [ ! -f "$SECRETS_FILE" ]; then
        info "No secrets file found"
        return
    fi

    echo
    read -p "Remove secrets file? (This contains your API keys/tokens) (y/n): " -n 1 -r
    echo
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Backup before removing
        local backup="$SECRETS_FILE.removed.$(date +%s)"
        cp "$SECRETS_FILE" "$backup"
        rm "$SECRETS_FILE"
        success "Removed secrets file (backup saved at $backup)"
    else
        success "Kept secrets file at $SECRETS_FILE"
    fi
}

# -----------------------------------------------------------------------------
# Restore Backups
# -----------------------------------------------------------------------------
restore_backups() {
    step "Restoring backups"

    local restored=0

    # Restore .zshrc
    local zshrc_backup
    zshrc_backup=$(find_latest_backup "$HOME/.zshrc.backup.")

    if [ -n "$zshrc_backup" ] && [ -f "$zshrc_backup" ]; then
        cp "$zshrc_backup" "$HOME/.zshrc"
        success "Restored .zshrc from $zshrc_backup"
        restored=1
    else
        warning "No .zshrc backup found"
    fi

    # Restore starship.toml
    local starship_backup
    starship_backup=$(find_latest_backup "$HOME/.config/starship.toml.backup.")

    if [ -n "$starship_backup" ] && [ -f "$starship_backup" ]; then
        cp "$starship_backup" "$HOME/.config/starship.toml"
        success "Restored starship.toml from $starship_backup"
        restored=1
    else
        info "No starship.toml backup found (this is OK)"
    fi

    # Restore custom directory
    local custom_backup
    custom_backup=$(find_latest_backup "$HOME/.oh-my-zsh/custom.backup.")

    if [ -n "$custom_backup" ] && [ -d "$custom_backup" ]; then
        # Only restore custom files, not the whole directory (preserve plugins)
        shopt -s nullglob
        for file in "$custom_backup"/*.zsh; do
            local basename
            basename=$(basename "$file")
            cp "$file" "$HOME/.oh-my-zsh/custom/$basename"
            info "Restored $basename from backup"
        done
        shopt -u nullglob
        success "Restored custom files from $custom_backup"
        restored=1
    else
        info "No custom directory backup found (this is OK)"
    fi

    return $restored
}

# -----------------------------------------------------------------------------
# Reset to Bash
# -----------------------------------------------------------------------------
reset_to_bash() {
    step "Resetting to bash"

    local current_shell
    current_shell="$(basename "$SHELL")"

    if [ "$current_shell" = "bash" ]; then
        info "Default shell is already bash"
        return
    fi

    local bash_path
    bash_path=$(command -v bash)

    if [ -z "$bash_path" ]; then
        error "Cannot find bash"
        return
    fi

    warning "Changing default shell to bash"
    echo
    read -p "Continue? (y/n): " -n 1 -r
    echo
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Skipped shell change"
        return
    fi

    if chsh -s "$bash_path" 2>&1; then
        success "Default shell changed to bash"
        info "Log out and log back in for the change to take full effect"
    else
        error "Failed to change shell automatically"
        info "Run manually: chsh -s $bash_path"
    fi
}

# -----------------------------------------------------------------------------
# Main Cleanup Flow
# -----------------------------------------------------------------------------
main() {
    echo -e "${CYAN}"
    cat << "EOF"
    ____
   / __ \___  _   _____  ____ _   __
  / / / / _ \| | / / _ \/ __ \ | / /
 / /_/ /  __/ |/ /  __/ / / / |/ /
/_____/\___/|___/\___/_/ /_/|___/

        Cleanup Script
EOF
    echo -e "${NC}"

    check_installation
    confirm_cleanup
    remove_devenv_files
    handle_secrets

    # Try to restore backups
    if restore_backups; then
        success "Backups restored successfully"
    else
        warning "No backups were found to restore"
        reset_to_bash
    fi

    echo
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Cleanup Complete${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${CYAN}Next Steps:${NC}"
    echo
    echo -e "  ${YELLOW}1. Start a new shell session:${NC}"
    echo -e "     ${BLUE}exec bash${NC}"
    echo
    echo -e "  ${YELLOW}2. Or open a new terminal window${NC}"
    echo
    echo -e "${CYAN}Note:${NC}"
    echo -e "  • Oh My Zsh, Starship, and plugins were NOT removed"
    echo -e "  • Only devenv configuration files were removed"
    echo -e "  • If you changed your default shell, log out and log back in"
    echo
}

# Run main function
main "$@"