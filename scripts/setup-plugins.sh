#!/usr/bin/env bash
# =============================================================================
# devenv Plugins Setup Script
# Purpose: Install and manage zsh plugins for Oh My Zsh
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

# Plugin definitions (easily expandable)
declare -a PLUGINS=(
    "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
    "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting"
    "zsh-completions|https://github.com/zsh-users/zsh-completions"
)

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

Install and manage zsh plugins for Oh My Zsh.

Options:
    --dry-run    Show what would be done without making changes
    --help       Show this help message

This script installs:
    - zsh-autosuggestions
    - zsh-syntax-highlighting
    - zsh-completions

Prerequisites:
    - Oh My Zsh must be installed (run setup-shell.sh first)

This script can be re-run to add new plugins as they are added to the list.

EOF
}

# -----------------------------------------------------------------------------
# Check Prerequisites
# -----------------------------------------------------------------------------
check_prerequisites() {
    step "Checking prerequisites"

    # Check if Oh My Zsh is installed
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        error "Oh My Zsh is not installed"
        info "Please run setup-shell.sh first"
        exit 1
    fi

    if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
        error "Oh My Zsh installation appears corrupted"
        info "Please run setup-shell.sh to reinstall"
        exit 1
    fi

    success "Oh My Zsh is installed"

    # Check if git is available
    if ! command -v git >/dev/null 2>&1; then
        error "git is not installed"
        info "Install with: sudo apt install git"
        exit 1
    fi

    success "git is installed"
}

# -----------------------------------------------------------------------------
# Install Plugin
# -----------------------------------------------------------------------------
install_plugin() {
    local plugin_name=$1
    local plugin_url=$2
    local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin_name"

    # Check if plugin already exists
    if [ -d "$plugin_dir" ]; then
        success "$plugin_name is already installed"
        return 0
    fi

    if [ $DRY_RUN -eq 1 ]; then
        info "[DRY RUN] Would install $plugin_name from $plugin_url"
        return 0
    fi

    info "Installing $plugin_name..."

    # Create plugins directory if it doesn't exist
    mkdir -p "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

    # Clone the plugin
    if git clone --depth=1 "$plugin_url" "$plugin_dir" 2>&1 >/dev/null; then
        success "Installed $plugin_name"
        return 0
    else
        error "Failed to install $plugin_name"
        warning "Check your internet connection and try again"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Install All Plugins
# -----------------------------------------------------------------------------
install_all_plugins() {
    step "Installing plugins"

    local failed=0
    local installed=0

    for plugin_info in "${PLUGINS[@]}"; do
        IFS='|' read -r plugin_name plugin_url <<< "$plugin_info"

        if install_plugin "$plugin_name" "$plugin_url"; then
            if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin_name" ] || [ $DRY_RUN -eq 1 ]; then
                # Was already installed or dry run
                :
            else
                installed=$((installed + 1))
            fi
        else
            failed=$((failed + 1))
        fi
    done

    echo

    if [ $DRY_RUN -eq 0 ]; then
        if [ $installed -gt 0 ]; then
            success "Installed $installed new plugin(s)"
        fi

        if [ $failed -gt 0 ]; then
            warning "$failed plugin(s) failed to install"
            return 1
        fi
    fi

    return 0
}

# -----------------------------------------------------------------------------
# Verify Installation
# -----------------------------------------------------------------------------
verify_installation() {
    step "Verifying plugin installation"

    local all_present=1

    for plugin_info in "${PLUGINS[@]}"; do
        IFS='|' read -r plugin_name plugin_url <<< "$plugin_info"
        local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin_name"

        if [ -d "$plugin_dir" ]; then
            success "$plugin_name is installed"
        else
            if [ $DRY_RUN -eq 0 ]; then
                warning "$plugin_name is NOT installed"
                all_present=0
            fi
        fi
    done

    if [ $all_present -eq 1 ] && [ $DRY_RUN -eq 0 ]; then
        success "All plugins are installed"
    fi
}

# -----------------------------------------------------------------------------
# Print Next Steps
# -----------------------------------------------------------------------------
print_next_steps() {
    echo
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Plugin Setup Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo

    if [ $DRY_RUN -eq 1 ]; then
        echo -e "${YELLOW}This was a dry run. No changes were made.${NC}"
        echo
        return
    fi

    echo -e "${CYAN}Next Steps:${NC}"
    echo
    echo -e "  ${YELLOW}1. Install devenv configurations:${NC}"
    echo -e "     ${BLUE}./install.sh${NC}"
    echo
    echo -e "  ${YELLOW}2. The installed plugins will be loaded automatically${NC}"
    echo -e "     ${CYAN}(after running install.sh which copies the .zshrc)${NC}"
    echo
    echo -e "${CYAN}Installed Plugins:${NC}"
    echo
    for plugin_info in "${PLUGINS[@]}"; do
        IFS='|' read -r plugin_name plugin_url <<< "$plugin_info"
        echo -e "  ${GREEN}•${NC} $plugin_name"
    done
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

     Plugins Setup Script
EOF
    echo -e "${NC}"

    parse_arguments "$@"
    check_prerequisites
    install_all_plugins
    verify_installation
    print_next_steps
}

# Run main function
main "$@"