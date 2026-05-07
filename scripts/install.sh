#!/usr/bin/env bash
# =============================================================================
# devenv Installation Script
# Purpose: Copy devenv configurations to home directory
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
BACKUP_CONFIGS=0
INSTALL_FAILED=0

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

Install devenv zsh configurations by copying files to home directory.

Options:
    --dry-run    Show what would be done without making changes
    --help       Show this help message

This script:
    - Validates devenv directory structure
    - Checks prerequisites (Oh My Zsh, Starship)
    - Optionally backs up existing configurations
    - Copies .zshrc to ~/.zshrc
    - Copies starship.toml to ~/.config/starship.toml
    - Copies custom/*.zsh to ~/.oh-my-zsh/custom/
    - Creates secrets file if it doesn't exist
    - Verifies installation

Prerequisites:
    - Run setup-shell.sh first
    - Run setup-plugins.sh first

This script can be re-run to update configurations from devenv.

EOF
}

# -----------------------------------------------------------------------------
# Get Script Directory and Validate Structure
# -----------------------------------------------------------------------------
validate_devenv_structure() {
    step "Validating devenv directory structure"

    # Get script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    DEVENV_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

    info "Script directory: $SCRIPT_DIR"
    info "devenv directory: $DEVENV_DIR"

    # Verify zsh directory exists
    if [ ! -d "$DEVENV_DIR/zsh" ]; then
        error "devenv directory structure is invalid"
        error "Expected: $DEVENV_DIR/zsh"
        exit 1
    fi

    success "Found zsh directory"

    # Verify .zshrc exists
    if [ ! -f "$DEVENV_DIR/zsh/.zshrc" ]; then
        error "Required file not found: $DEVENV_DIR/zsh/.zshrc"
        exit 1
    fi

    success "Found .zshrc"

    # Verify starship.toml exists
    if [ ! -f "$DEVENV_DIR/zsh/starship.toml" ]; then
        error "Required file not found: $DEVENV_DIR/zsh/starship.toml"
        exit 1
    fi

    success "Found starship.toml"

    # Verify custom directory exists
    if [ ! -d "$DEVENV_DIR/zsh/custom" ]; then
        error "Required directory not found: $DEVENV_DIR/zsh/custom"
        exit 1
    fi

    success "Found custom directory"

    # Verify files are readable
    if [ ! -r "$DEVENV_DIR/zsh/.zshrc" ]; then
        error "Cannot read $DEVENV_DIR/zsh/.zshrc"
        exit 1
    fi

    if [ ! -r "$DEVENV_DIR/zsh/starship.toml" ]; then
        error "Cannot read $DEVENV_DIR/zsh/starship.toml"
        exit 1
    fi

    success "All required files are readable"
}

# -----------------------------------------------------------------------------
# Check Prerequisites
# -----------------------------------------------------------------------------
check_prerequisites() {
    step "Checking prerequisites"

    local missing=0

    # Check if Oh My Zsh is installed
    if [ -d "$HOME/.oh-my-zsh" ] && [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
        success "Oh My Zsh is installed"
    else
        error "Oh My Zsh is not installed"
        info "Please run setup-shell.sh first"
        missing=1
    fi

    # Check if Starship is installed
    if command -v starship >/dev/null 2>&1; then
        success "Starship is installed"
    else
        error "Starship is not installed"
        info "Please run setup-shell.sh first"
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Ask to Backup
# -----------------------------------------------------------------------------
ask_to_backup() {
    if [ $DRY_RUN -eq 1 ]; then
        info "[DRY RUN] Would ask about backing up existing configurations"
        BACKUP_CONFIGS=1  # Assume yes for dry run
        return
    fi

    step "Backup existing configurations?"

    echo
    read -p "Backup existing configs before overwriting? (y/n): " -n 1 -r
    echo
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        BACKUP_CONFIGS=1
        info "Will create backups with timestamp"
    else
        BACKUP_CONFIGS=0
        warning "Will overwrite existing configs without backup"
    fi
}

# -----------------------------------------------------------------------------
# Backup Existing Configurations
# -----------------------------------------------------------------------------
backup_existing_configs() {
    if [ $BACKUP_CONFIGS -eq 0 ]; then
        return
    fi

    step "Backing up existing configurations"

    local timestamp
    timestamp=$(date +%s)
    local backed_up=0

    # Backup .zshrc (if it's a regular file, not a symlink)
    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        if [ $DRY_RUN -eq 1 ]; then
            info "[DRY RUN] Would backup: $HOME/.zshrc -> $HOME/.zshrc.backup.$timestamp"
        else
            cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$timestamp"
            info "Backed up .zshrc to .zshrc.backup.$timestamp"
        fi
        backed_up=1
    fi

    # Backup starship.toml (if it's a regular file, not a symlink)
    if [ -f "$HOME/.config/starship.toml" ] && [ ! -L "$HOME/.config/starship.toml" ]; then
        if [ $DRY_RUN -eq 1 ]; then
            info "[DRY RUN] Would backup: $HOME/.config/starship.toml -> $HOME/.config/starship.toml.backup.$timestamp"
        else
            cp "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.backup.$timestamp"
            info "Backed up starship.toml to starship.toml.backup.$timestamp"
        fi
        backed_up=1
    fi

    # Backup custom directory (if it's a real directory, not a symlink)
    if [ -d "$HOME/.oh-my-zsh/custom" ] && [ ! -L "$HOME/.oh-my-zsh/custom" ]; then
        if [ $DRY_RUN -eq 1 ]; then
            info "[DRY RUN] Would backup: $HOME/.oh-my-zsh/custom -> $HOME/.oh-my-zsh/custom.backup.$timestamp"
        else
            cp -r "$HOME/.oh-my-zsh/custom" "$HOME/.oh-my-zsh/custom.backup.$timestamp"
            info "Backed up custom directory to custom.backup.$timestamp"
        fi
        backed_up=1
    fi

    if [ $backed_up -eq 0 ]; then
        info "No existing configurations to backup"
    else
        success "Backups completed"
    fi
}

# -----------------------------------------------------------------------------
# Copy .zshrc
# -----------------------------------------------------------------------------
copy_zshrc() {
    step "Copying .zshrc"

    if [ $DRY_RUN -eq 1 ]; then
        info "[DRY RUN] Would copy: $DEVENV_DIR/zsh/.zshrc -> $HOME/.zshrc"
        info "[DRY RUN] Would set permissions: 644"
        return
    fi

    # Remove existing file/symlink
    if [ -f "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ]; then
        rm -f "$HOME/.zshrc"
    fi

    # Copy file
    if cp "$DEVENV_DIR/zsh/.zshrc" "$HOME/.zshrc"; then
        success "Copied .zshrc"
    else
        error "Failed to copy .zshrc"
        INSTALL_FAILED=1
        return
    fi

    # Set permissions
    if chmod 644 "$HOME/.zshrc"; then
        success "Set .zshrc permissions to 644"
    else
        error "Failed to set permissions on .zshrc"
        INSTALL_FAILED=1
    fi
}

# -----------------------------------------------------------------------------
# Copy Starship Config
# -----------------------------------------------------------------------------
copy_starship_config() {
    step "Copying starship configuration"

    # Create .config directory if it doesn't exist
    if [ $DRY_RUN -eq 0 ]; then
        mkdir -p "$HOME/.config"
    fi

    if [ $DRY_RUN -eq 1 ]; then
        info "[DRY RUN] Would copy: $DEVENV_DIR/zsh/starship.toml -> $HOME/.config/starship.toml"
        info "[DRY RUN] Would set permissions: 644"
        return
    fi

    # Remove existing file/symlink
    if [ -f "$HOME/.config/starship.toml" ] || [ -L "$HOME/.config/starship.toml" ]; then
        rm -f "$HOME/.config/starship.toml"
    fi

    # Copy file
    if cp "$DEVENV_DIR/zsh/starship.toml" "$HOME/.config/starship.toml"; then
        success "Copied starship.toml"
    else
        error "Failed to copy starship.toml"
        INSTALL_FAILED=1
        return
    fi

    # Set permissions
    if chmod 644 "$HOME/.config/starship.toml"; then
        success "Set starship.toml permissions to 644"
    else
        error "Failed to set permissions on starship.toml"
        INSTALL_FAILED=1
    fi
}

# -----------------------------------------------------------------------------
# Copy Custom Files
# -----------------------------------------------------------------------------
copy_custom_files() {
    step "Copying custom files"

    local custom_src="$DEVENV_DIR/zsh/custom"
    local custom_dest="$HOME/.oh-my-zsh/custom"

    # Create custom directory if it doesn't exist
    if [ $DRY_RUN -eq 0 ]; then
        mkdir -p "$custom_dest"
    fi

    # Copy all .zsh files except .example files
    shopt -s nullglob
    local copied=0

    for file in "$custom_src"/*.zsh; do
        local basename
        basename=$(basename "$file")

        # Skip .example files
        if [[ "$basename" == *.example ]]; then
            info "Skipping example file: $basename"
            continue
        fi

        if [ $DRY_RUN -eq 1 ]; then
            info "[DRY RUN] Would copy: $file -> $custom_dest/$basename"
            info "[DRY RUN] Would set permissions: 644"
            copied=$((copied + 1))
            continue
        fi

        # Copy file
        if cp "$file" "$custom_dest/$basename"; then
            # Set permissions
            if chmod 644 "$custom_dest/$basename"; then
                success "Copied $basename (644)"
                copied=$((copied + 1))
            else
                error "Failed to set permissions on $basename"
                INSTALL_FAILED=1
            fi
        else
            error "Failed to copy $basename"
            INSTALL_FAILED=1
        fi
    done

    shopt -u nullglob

    if [ $copied -eq 0 ]; then
        warning "No custom files found to copy"
    else
        success "Copied $copied custom file(s)"
    fi
}

# -----------------------------------------------------------------------------
# Create Secrets File
# -----------------------------------------------------------------------------
create_secrets_file() {
    step "Setting up secrets file"

    local secrets_file="$HOME/.oh-my-zsh/custom/99-secrets.zsh"
    local secrets_example="$DEVENV_DIR/zsh/custom/99-secrets.zsh.example"

    # If secrets file already exists, leave it alone
    if [ -f "$secrets_file" ] && [ ! -L "$secrets_file" ]; then
        success "Secrets file already exists (preserving it)"

        # Verify it's readable
        if [ ! -r "$secrets_file" ]; then
            error "Secrets file exists but is not readable"

            if [ $DRY_RUN -eq 0 ]; then
                info "Fixing permissions..."
                if chmod 644 "$secrets_file"; then
                    success "Fixed permissions on secrets file"
                else
                    error "Failed to fix permissions"
                    INSTALL_FAILED=1
                fi
            fi
        fi
        return 0
    fi

    if [ $DRY_RUN -eq 1 ]; then
        info "[DRY RUN] Would create secrets file at $secrets_file"
        info "[DRY RUN] Would set permissions: 644"
        return
    fi

    # If it's a symlink, remove it
    if [ -L "$secrets_file" ]; then
        warning "Secrets file is a symlink (removing it)"
        rm -f "$secrets_file"
    fi

    info "Creating secrets file..."

    # Try to copy from example first
    if [ -f "$secrets_example" ]; then
        if cp "$secrets_example" "$secrets_file"; then
            info "Created secrets file from example"
        else
            error "Failed to copy secrets example"
            INSTALL_FAILED=1
            return 1
        fi
    else
        # Create minimal secrets file
        cat > "$secrets_file" << 'EOF'
# -----------------------------------------------------------------------------
# Local Secrets - NEVER commit this file with real values
# -----------------------------------------------------------------------------
# This file is sourced by your .zshrc and should contain environment variables
# for API keys, tokens, and other sensitive information.
#
# Example:
# export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
# export OPENAI_API_KEY="sk-xxxxxxxxxxxx"
# export AWS_ACCESS_KEY_ID="xxxxxxxxxxxx"
# export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxx"

EOF
        if [ $? -eq 0 ]; then
            info "Created minimal secrets file"
        else
            error "Failed to create secrets file"
            INSTALL_FAILED=1
            return 1
        fi
    fi

    # Set proper permissions
    if chmod 644 "$secrets_file"; then
        success "Set secrets file permissions to 644"
    else
        error "Failed to set permissions on secrets file"
        INSTALL_FAILED=1
    fi

    # Verify the file is readable
    if [ ! -r "$secrets_file" ]; then
        error "Secrets file was created but is not readable"
        INSTALL_FAILED=1
    fi
}

# -----------------------------------------------------------------------------
# Verify Installation
# -----------------------------------------------------------------------------
verify_installation() {
    step "Verifying installation"

    local verification_failed=0

    # Check .zshrc exists and is readable
    if [ -f "$HOME/.zshrc" ] && [ -r "$HOME/.zshrc" ]; then
        success ".zshrc is present and readable"
    else
        error ".zshrc is missing or not readable"
        verification_failed=1
    fi

    # Check starship.toml exists and is readable
    if [ -f "$HOME/.config/starship.toml" ] && [ -r "$HOME/.config/starship.toml" ]; then
        success "starship.toml is present and readable"
    else
        error "starship.toml is missing or not readable"
        verification_failed=1
    fi

    # Check secrets file exists and is readable
    if [ -f "$HOME/.oh-my-zsh/custom/99-secrets.zsh" ] && [ -r "$HOME/.oh-my-zsh/custom/99-secrets.zsh" ]; then
        success "Secrets file is present and readable"
    else
        error "Secrets file is missing or not readable"
        verification_failed=1
    fi

    if [ $DRY_RUN -eq 1 ]; then
        info "[DRY RUN] Skipping syntax and source tests"
        return
    fi

    # Test zsh configuration syntax
    if zsh -n "$HOME/.zshrc" 2>/dev/null; then
        success "ZSH configuration syntax is valid"
    else
        warning "ZSH configuration has syntax issues"
        info "Try running: zsh -n ~/.zshrc"
        verification_failed=1
    fi

    # Try to actually source the config in a subshell
    if zsh -c "source ~/.zshrc && echo 'Config loaded successfully'" >/dev/null 2>&1; then
        success "ZSH configuration loads without errors"
    else
        error "ZSH configuration has errors when sourcing"
        info "Try running: zsh -c 'source ~/.zshrc'"
        verification_failed=1
    fi

    if [ $verification_failed -eq 0 ]; then
        success "Installation verification complete - all checks passed"
    else
        error "Installation verification found issues"
        INSTALL_FAILED=1
    fi
}

# -----------------------------------------------------------------------------
# Print Next Steps
# -----------------------------------------------------------------------------
print_next_steps() {
    echo
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    if [ $INSTALL_FAILED -eq 0 ]; then
        echo -e "${GREEN}  Installation Complete!${NC}"
    else
        echo -e "${YELLOW}  Installation Complete (with warnings)${NC}"
    fi
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo

    if [ $DRY_RUN -eq 1 ]; then
        echo -e "${YELLOW}This was a dry run. No changes were made.${NC}"
        echo
        return
    fi

    if [ $INSTALL_FAILED -eq 1 ]; then
        echo -e "${YELLOW}⚠ Some issues were encountered during installation.${NC}"
        echo -e "${YELLOW}  Review the warnings above and fix them if needed.${NC}"
        echo
    fi

    echo -e "${CYAN}Next Steps:${NC}"
    echo
    echo -e "  ${YELLOW}1. Start using your new configuration:${NC}"
    echo -e "     ${BLUE}exec zsh${NC}"
    echo
    echo -e "  ${YELLOW}2. Add your secrets:${NC}"
    echo -e "     ${BLUE}nano ~/.oh-my-zsh/custom/99-secrets.zsh${NC}"
    echo
    echo -e "  ${YELLOW}3. To update configurations in the future:${NC}"
    echo -e "     ${BLUE}./install.sh${NC}"
    echo
    echo -e "${CYAN}Tips:${NC}"
    echo
    echo -e "  • Your configs are now copied to your home directory"
    echo -e "  • You can edit them directly: ${BLUE}~/.zshrc${NC}"
    echo -e "  • Re-run this script to get updates from devenv"
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

    parse_arguments "$@"
    validate_devenv_structure
    check_prerequisites
    ask_to_backup
    backup_existing_configs
    copy_zshrc
    copy_starship_config
    copy_custom_files
    create_secrets_file
    verify_installation
    print_next_steps

    # Exit with appropriate code
    if [ $INSTALL_FAILED -eq 1 ]; then
        exit 1
    fi
}

# Run main function
main "$@"