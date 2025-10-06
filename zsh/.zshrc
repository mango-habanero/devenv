# -----------------------------------------------------------------------------
# File:    ~/.zshrc
# Purpose: Minimal, opinionated Zsh configuration for development (Starship + Oh My Zsh)
# Created: 2025-09-01
# Maintainer: <Mango Habanero> <main@mango-habanero.dev>
# SPDX-License-Identifier: MIT
#
# Design Philosophy:
#  - Keep this file minimal; all custom aliases/functions/env vars live in $ZSH_CUSTOM/*.zsh
#  - Secrets go in $ZSH_CUSTOM/99-secrets.zsh.example and must NEVER be committed upstream
#  - Starship handles prompt rendering; Oh My Zsh provides plugin ecosystem
#  - This file defines ONLY core shell behavior, history, completions, and plugin loading
# -----------------------------------------------------------------------------

# -------------------------
# PATH & Language Toolchains
# -------------------------
# Prefer user-local bins so pipx/uv/pnpm/gh/cargo installs are discovered first.
# Order matters: earlier entries take precedence.
export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.local/share/pnpm:$HOME/.cargo/bin:/usr/local/go/bin:/usr/local/bin:$PATH"

# -------------------------
# Oh My Zsh Configuration
# -------------------------
export ZSH="$HOME/.oh-my-zsh"

# Disable OMZ theme; let Starship handle the prompt
ZSH_THEME=""

# Update behavior: auto-update weekly (remove DISABLE_AUTO_UPDATE to allow this)
HYPHEN_INSENSITIVE="true"
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 7

# -------------------------
# Interactive Shell Guard
# -------------------------
# Skip interactive-only config for non-interactive shells (scripts, CI, etc.)
# PATH and ZSH variables above apply regardless of shell type.
[[ -z "$PS1" ]] && return

# -------------------------
# Performance & UX Options
# -------------------------
ENABLE_CORRECTION="true"               # Enable command spell-correction (disable if too intrusive)
COMPLETION_WAITING_DOTS="true"         # Show dots while waiting for completion
DISABLE_UNTRACKED_FILES_DIRTY="true"   # Speed up git status in large repos
HIST_STAMPS="yyyy-mm-dd"               # History timestamp format

# -------------------------
# Plugins
# -------------------------
# Conservative list: only essential plugins enabled by default.
# Verify custom plugins are installed under $ZSH/custom/plugins/ before adding.
#
# Required custom plugins (install separately):
#   git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
#   git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
#   git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions

plugins=(
  # Version Control
  git
  gitignore

  # Python Ecosystem
  python
  pip
  virtualenv

  # Node.js / JavaScript
  node
  npm
  nvm

  # Container Orchestration
  kubectl

  # Development Tools
  httpie

  # Enhanced Shell Experience (require manual installation - see above)
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
)

# Load Oh My Zsh
source "$ZSH/oh-my-zsh.sh"

# -------------------------
# Enhanced History Configuration
# -------------------------
HISTSIZE=50000                          # Lines of history to keep in memory
SAVEHIST=50000                          # Lines of history to save to file
setopt INC_APPEND_HISTORY               # Write to history file immediately
setopt APPEND_HISTORY                   # Append to history file, don't overwrite
setopt HIST_EXPIRE_DUPS_FIRST          # Expire duplicate entries first when trimming
setopt HIST_IGNORE_DUPS                 # Don't record an entry that was just recorded
setopt HIST_IGNORE_ALL_DUPS            # Delete old recorded entry if new is duplicate
setopt HIST_IGNORE_SPACE                # Don't record entries starting with space
setopt HIST_FIND_NO_DUPS               # Don't display duplicates when searching
setopt HIST_SAVE_NO_DUPS               # Don't write duplicate entries to history file
setopt SHARE_HISTORY                    # Share history between all sessions
setopt HIST_REDUCE_BLANKS              # Remove superfluous blanks from history

# -------------------------
# Completion System Styling
# -------------------------
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'     # Case-insensitive completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"    # Colorized completion listings
zstyle ':completion:*' menu select                          # Interactive menu selection

# -------------------------
# Load Custom Configuration Files
# -------------------------
# Custom files are sourced explicitly for safety and clarity.
# Files are loaded in numbered order for predictable precedence:
#   01-environment.zsh  -> Environment variables, PATH modifications, tool configs
#   02-aliases.zsh      -> Command aliases and small wrapper functions
#   03-functions.zsh    -> Complex reusable functions (dev workflows, k8s, docker)
#   99-secrets.zsh.example      -> Local secrets (API keys, tokens) - NEVER commit with real values

[[ -f "$ZSH_CUSTOM/01-environment.zsh" ]] && source "$ZSH_CUSTOM/01-environment.zsh"
[[ -f "$ZSH_CUSTOM/02-aliases.zsh" ]]     && source "$ZSH_CUSTOM/02-aliases.zsh"
[[ -f "$ZSH_CUSTOM/03-functions.zsh" ]]   && source "$ZSH_CUSTOM/03-functions.zsh"

# Secrets file: ensure restricted permissions and source if exists
if [[ -f "$ZSH_CUSTOM/99-secrets.zsh" ]]; then
  chmod 600 "$ZSH_CUSTOM/99-secrets.zsh" 2>/dev/null || true
  source "$ZSH_CUSTOM/99-secrets.zsh"
fi

# -------------------------
# Starship Prompt (MUST be at end of interactive config)
# -------------------------
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  echo "Warning: starship not found. Install from: https://starship.rs"
fi

# -----------------------------------------------------------------------------
# Tool-Specific Initialization (keep at end)
# -----------------------------------------------------------------------------

# SDKMAN - Java version manager
# This MUST be at the end for SDKMAN to work correctly
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
