# -----------------------------------------------------------------------------
# File:    02-aliases.zsh
# Purpose: Lightweight, user-level shell aliases and small argument-forwarding helpers
# Maintainer: <Mango Habanero> <main@mango-habanero.dev>
# Created: 2025-09-01
# SPDX-License-Identifier: MIT
#
# Notes:
#  - Prefer tiny functions for aliases that must forward arguments.
#  - Avoid alias name collisions with existing commands or functions.
#  - Document any aliases that wrap destructive operations (e.g., prune).
#  - Cross-platform compatible: Linux, macOS, BSD
# -----------------------------------------------------------------------------

# If any of these names are currently aliases, remove them so we can safely define
# functions with the same names. This avoids "defining function based on alias"
# parse errors when sourcing the file multiple times or after other files define aliases.
for _n in gwip gcb gundo dps dpa di dlog dexec klogsf kexec activate pipglobal; do
  if alias "$_n" >/dev/null 2>&1; then
    unalias "$_n" 2>/dev/null || true
  fi
done
unset _n


# -------------------------
# Git workflow (aliases + tiny helpers)
# -------------------------
alias gst='git status --short --branch'        # compact status with branch
alias gco='git switch'                         # gco <branch>
alias gcom='git switch main || git switch master'
alias gdev='git switch dev'
alias gpr='git pull --rebase'
alias gpf='git push --force-with-lease'       # explicit; safer than raw force
alias glog='git log --oneline --graph --decorate --all'

# safer "WIP" commit: only commits when there are staged changes
gwip() {
  git add -A
  if git diff --cached --quiet; then
    echo "No staged changes to commit."
    return 0
  fi
  git commit -m "${1:-WIP: work in progress}"
}

# create-and-switch helper
gcb() { git switch -c "$1"; }                   # gcb <new-branch>

# quick undo of last commit but keep changes staged (soft reset)
gundo() { git reset --soft HEAD~1; echo "Rewound last commit (changes staged)"; }

# -------------------------
# Docker (functions so args forward cleanly)
# -------------------------
dps() { docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"; }
dpa() { docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"; }
di()  { docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"; }
alias dprune='docker system prune -af --volumes'
dlog() { docker logs -f "$@"; }                 # dlog <container>
dexec() { docker exec -it "$@"; }               # dexec <container> <cmd...>

# -------------------------
# Kubernetes
# -------------------------
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods -A'                # all namespaces
alias kgs='kubectl get svc'
alias kgd='kubectl get deployment'
alias kdesc='kubectl describe'
klogsf() { kubectl logs -f "$@"; }              # explicit function name (accepts args)
kexec() { kubectl exec -it "$@"; }              # kexec <pod> -- <cmd>
alias kctx='kubectl config current-context'
kctxs() { kubectl config get-contexts -o name; } # list names only

# -------------------------
# Python (uv first)
# -------------------------
alias py='python3'
alias pip='pip3'
alias venv='uv venv'                            # use uv for venv management
activate() {
  if [ -f ".venv/bin/activate" ]; then
    # shellcheck disable=SC1090
    source .venv/bin/activate
  elif [ -f "venv/bin/activate" ]; then
    # shellcheck disable=SC1090
    source venv/bin/activate
  else
    echo "No local venv found. Use 'uv venv' or 'venv <path>'."
  fi
}
alias deactivate='deactivate'
alias pipr='pip install -r requirements.txt'
alias pipf='pip freeze > requirements.txt'
pipglobal() { PIP_REQUIRE_VIRTUALENV=0 pip3 "$@"; }  # bypass PIP_REQUIRE_VIRTUALENV when needed

# -------------------------
# Node
# -------------------------
alias ni='npm install'
alias nid='npm install --save-dev'
alias nr='npm run'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'

# -------------------------
# System utils
# -------------------------
alias ll='ls -lahF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'            # display PATH one entry per line
alias now='date +"%Y-%m-%d %T"'                 # current date/time
alias reload='source ~/.zshrc'                  # reload shell config

# -------------------------
# OS-specific system management
# -------------------------
# Package manager upgrade (OS-aware)
case "$(uname -s)" in
  Linux*)
    # Detect Linux distribution
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      case "$ID" in
        ubuntu|debian|pop|linuxmint)
          alias upgrade='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
          ;;
        fedora|rhel|centos|rocky|almalinux)
          alias upgrade='sudo dnf upgrade -y && sudo dnf autoremove -y'
          ;;
        arch|manjaro|endeavouros)
          alias upgrade='sudo pacman -Syu --noconfirm'
          ;;
        opensuse*|sles)
          alias upgrade='sudo zypper refresh && sudo zypper update -y'
          ;;
        alpine)
          alias upgrade='sudo apk update && sudo apk upgrade'
          ;;
        *)
          # Generic Linux fallback - no package manager assumed
          alias upgrade='echo "Unknown Linux distribution. Please run your package manager manually."'
          ;;
      esac
    else
      alias upgrade='echo "Cannot detect Linux distribution. Please run your package manager manually."'
    fi
    ;;
  Darwin*)
    # macOS - check for Homebrew
    if command -v brew >/dev/null 2>&1; then
      alias upgrade='brew update && brew upgrade && brew cleanup'
    else
      alias upgrade='echo "Homebrew not found. Install from https://brew.sh or use App Store updates."'
    fi
    ;;
  FreeBSD*|OpenBSD*|NetBSD*)
    # BSD systems
    alias upgrade='sudo pkg update && sudo pkg upgrade -y'
    ;;
  *)
    # Unknown OS
    alias upgrade='echo "Unknown operating system. Please run your package manager manually."'
    ;;
esac

# -------------------------
# Dev server shortcuts
# -------------------------
alias serve='python3 -m http.server'
alias pyserver='python3 -m http.server 8000'
alias nodeserver='npx http-server -p 8080'

# -------------------------
# Monitoring and system info (OS-aware)
# -------------------------
# Network ports: use ss on Linux, netstat on macOS/BSD
case "$(uname -s)" in
  Linux*)
    if command -v ss >/dev/null 2>&1; then
      alias ports='ss -tulwnp'
    else
      alias ports='netstat -tulnp'
    fi
    ;;
  Darwin*)
    # macOS netstat doesn't have -p flag, and uses different format
    alias ports='netstat -anvp tcp && netstat -anvp udp'
    ;;
  FreeBSD*|OpenBSD*|NetBSD*)
    alias ports='sockstat -46l'
    ;;
  *)
    # Fallback to basic netstat
    alias ports='netstat -an | grep LISTEN'
    ;;
esac

# Memory info (OS-aware)
case "$(uname -s)" in
  Linux*)
    alias meminfo='free -m -l -t'
    ;;
  Darwin*)
    # macOS doesn't have 'free', use vm_stat instead
    alias meminfo='vm_stat && echo && top -l 1 -s 0 | grep PhysMem'
    ;;
  FreeBSD*|OpenBSD*|NetBSD*)
    alias meminfo='top -d1 | head -n 5'
    ;;
esac

# Process sorting (cross-platform)
alias psmem='ps aux | sort -nr -k 4 | head -20'
alias pscpu='ps aux | sort -nr -k 3 | head -20'

# CPU info (OS-aware)
case "$(uname -s)" in
  Linux*)
    alias cpuinfo='lscpu'
    ;;
  Darwin*)
    alias cpuinfo='sysctl -n machdep.cpu.brand_string && sysctl -n hw.ncpu && echo "cores"'
    ;;
  FreeBSD*|OpenBSD*|NetBSD*)
    alias cpuinfo='sysctl hw.model hw.ncpu'
    ;;
esac

# Disk space (universal)
alias diskspace='df -h'