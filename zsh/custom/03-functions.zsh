# -----------------------------------------------------------------------------
# File:    03-functions.zsh
# Purpose: Reusable shell functions for developer workflows (uv, docker, kubectl)
# Maintainer: <Mango Habanero> <main@mango-habanero.dev>
# Created: 2025-09-01
# Version: 0.2
# SPDX-License-Identifier: MIT
#
# Requirements:
#   - zsh, oh-my-zsh
#   - uv (venv management), docker (container runtime), kubectl
#
# Security / Best practices:
#  - Do NOT hardcode secrets or credentials in this file.
#  - Keep functions small, idempotent, and defensive (check command availability).
#  - Cross-platform compatible: Linux, macOS, BSD
# -----------------------------------------------------------------------------


# --------------------------------------------------------------------------
# OS Detection Helper
# --------------------------------------------------------------------------
__detect_os() {
  case "$(uname -s)" in
    Linux*)   echo "linux" ;;
    Darwin*)  echo "macos" ;;
    FreeBSD*) echo "freebsd" ;;
    OpenBSD*) echo "openbsd" ;;
    NetBSD*)  echo "netbsd" ;;
    *)        echo "unknown" ;;
  esac
}

# --------------------------------------------------------------------------
# Simple helpers
# --------------------------------------------------------------------------
__info() { printf "→ %s\n" "$1"; }
__warn() { printf "⚠ %s\n" "$1" >&2; }
__error() { printf "✗ %s\n" "$1" >&2; }

# --------------------------------------------------------------------------
# Python Development (uv required)
# --------------------------------------------------------------------------
# Create and activate a virtual environment using uv (assumed available).
mkvenv() {
  if [ -z "$1" ]; then
    echo "Usage: mkvenv <env-path>     (e.g. mkvenv .venv or mkvenv ~/envs/myenv)"
    return 1
  fi

  if ! command -v uv >/dev/null 2>&1; then
    __error "uv not found. Install from: https://github.com/astral-sh/uv"
    return 1
  fi

  __info "creating virtual environment with uv"
  uv venv "$1" || { __error "uv venv failed"; return 1; }

  # activate if activation script exists
  if [ -f "$1/bin/activate" ]; then
    # shellcheck disable=SC1090
    source "$1/bin/activate"
    pip install --upgrade pip setuptools wheel >/dev/null 2>&1 || true
    echo "Virtual environment '$1' created and activated!"
  else
    __warn "Created venv at '$1' but activation script not found."
  fi
}

# Quick Python project scaffold; uses uv for venv
pyproject() {
  if [ -z "$1" ]; then
    echo "Usage: pyproject <project_name>"
    return 1
  fi

  if ! command -v uv >/dev/null 2>&1; then
    __error "uv not found. Install from: https://github.com/astral-sh/uv"
    return 1
  fi

  mkdir -p "$1" && cd "$1" || return 1

  __info "creating .venv with uv"
  uv venv || { __error "uv venv failed"; }

  mkdir -p src tests docs
  touch README.md requirements.txt .gitignore pyproject.toml

  cat > .gitignore << 'EOF'
# Python
.venv/
venv/
__pycache__/
*.py[cod]
*.egg-info/
*.pyc
.pytest_cache/
.coverage

# OS / IDE
.vscode/
.idea/
.DS_Store
Thumbs.db

# node
node_modules/

# environment
.env
.env.local
EOF

  cat > README.md << EOF
# $1

## Description
Brief description of your project.

## Setup
\`\`\`bash
mkvenv .venv
source .venv/bin/activate
\`\`\`

## Usage
\`\`\`bash
# Usage examples
\`\`\`
EOF

  echo "Python project '$1' created (uv used for venv)."
}

# --------------------------------------------------------------------------
# Kubernetes helpers
# --------------------------------------------------------------------------
kswitch() {
  if ! command -v kubectl >/dev/null 2>&1; then
    __error "kubectl not found in PATH"
    return 1
  fi

  if [ -z "$1" ]; then
    echo "Available contexts:"
    kubectl config get-contexts
    return 0
  fi
  kubectl config use-context "$1" && echo "Switched to context: $1"
}

# klogs: follow logs. Accepts optional namespace as -n and/or container name.
# Usage: klogs <pod-name> [container-name] [-n namespace]
klogs() {
  if ! command -v kubectl >/dev/null 2>&1; then
    __error "kubectl not found in PATH"
    return 1
  fi

  if [ -z "$1" ]; then
    echo "Usage: klogs <pod-name> [container-name] [-n namespace]"
    return 1
  fi

  local pod="$1"
  shift
  local container=""
  local ns=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -n) ns="-n $2"; shift 2 ;;
      -n=*) ns="-n ${1#*=}"; shift ;;
      *) [ -z "$container" ] && container="$1"; shift ;;
    esac
  done

  if [ -n "$container" ]; then
    kubectl logs -f $ns "$pod" -c "$container"
  else
    kubectl logs -f $ns "$pod"
  fi
}

# Exec into a pod; supports namespace flag (-n)
# Usage: ksh <pod-name> [container-name] [-n namespace]
ksh() {
  if ! command -v kubectl >/dev/null 2>&1; then
    __error "kubectl not found in PATH"
    return 1
  fi

  if [ -z "$1" ]; then
    echo "Usage: ksh <pod-name> [container-name] [-n namespace]"
    return 1
  fi

  local pod="$1"
  shift
  local container=""
  local ns=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -n) ns="-n $2"; shift 2 ;;
      -n=*) ns="-n ${1#*=}"; shift ;;
      *) [ -z "$container" ] && container="$1"; shift ;;
    esac
  done

  if [ -n "$container" ]; then
    kubectl exec -it $ns "$pod" -c "$container" -- /bin/bash
  else
    kubectl exec -it $ns "$pod" -- /bin/bash
  fi
}

# --------------------------------------------------------------------------
# Docker helpers (cross-platform)
# --------------------------------------------------------------------------
# devdb: start dev DB containers. Uses short image names (Docker handles registry).
# Defaults are ephemeral/dev-only.
devdb() {
  if ! command -v docker >/dev/null 2>&1; then
    __error "docker not found in PATH"
    return 1
  fi

  case "$1" in
    postgres|pg)
      docker run --name dev-postgres \
        -e POSTGRES_PASSWORD=devpass \
        -e POSTGRES_DB=devdb \
        -p 5432:5432 -d postgres:latest
      echo "PostgreSQL started on port 5432 (user: postgres, password: devpass, db: devdb)"
      ;;
    redis)
      docker run --name dev-redis -p 6379:6379 -d redis:latest
      echo "Redis started on port 6379"
      ;;
    mongo)
      docker run --name dev-mongo -p 27017:27017 -d mongo:latest
      echo "MongoDB started on port 27017"
      ;;
    mysql)
      docker run --name dev-mysql \
        -e MYSQL_ROOT_PASSWORD=devpass \
        -e MYSQL_DATABASE=devdb \
        -p 3306:3306 -d mysql:latest
      echo "MySQL started on port 3306 (user: root, password: devpass, db: devdb)"
      ;;
    *)
      echo "Usage: devdb [postgres|redis|mongo|mysql]"
      echo ""
      echo "Available databases:"
      echo "  postgres - PostgreSQL on port 5432"
      echo "  redis    - Redis on port 6379"
      echo "  mongo    - MongoDB on port 27017"
      echo "  mysql    - MySQL on port 3306"
      ;;
  esac
}

# stopdb: stop and remove dev containers
stopdb() {
  if ! command -v docker >/dev/null 2>&1; then
    __error "docker not found in PATH"
    return 1
  fi

  case "$1" in
    postgres|pg)
      docker stop dev-postgres 2>/dev/null || true
      docker rm dev-postgres 2>/dev/null || true
      echo "Stopped and removed dev-postgres"
      ;;
    redis)
      docker stop dev-redis 2>/dev/null || true
      docker rm dev-redis 2>/dev/null || true
      echo "Stopped and removed dev-redis"
      ;;
    mongo)
      docker stop dev-mongo 2>/dev/null || true
      docker rm dev-mongo 2>/dev/null || true
      echo "Stopped and removed dev-mongo"
      ;;
    mysql)
      docker stop dev-mysql 2>/dev/null || true
      docker rm dev-mysql 2>/dev/null || true
      echo "Stopped and removed dev-mysql"
      ;;
    all)
      docker stop dev-postgres dev-redis dev-mongo dev-mysql 2>/dev/null || true
      docker rm dev-postgres dev-redis dev-mongo dev-mysql 2>/dev/null || true
      echo "All development databases stopped and removed"
      ;;
    *)
      echo "Usage: stopdb [postgres|redis|mongo|mysql|all]"
      ;;
  esac
}

# --------------------------------------------------------------------------
# Development utilities
# --------------------------------------------------------------------------
cleanup() {
  echo "🧹 Cleaning up development environment..."

  if command -v docker >/dev/null 2>&1; then
    echo "  → Pruning docker containers/images/volumes..."
    docker container prune -f 2>/dev/null || true
    docker image prune -f 2>/dev/null || true
    docker volume prune -f 2>/dev/null || true
  else
    echo "  → docker not found; skipping container prune."
  fi

  echo "  → Showing largest node_modules folders (first 10)"
  find . -name "node_modules" -type d -prune -exec du -sh {} \; 2>/dev/null | sort -h | tail -n 10 || true

  echo "  → Cleaning Python cache files..."
  find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
  find . -name "*.pyc" -delete 2>/dev/null || true

  echo "✅ Cleanup complete!"
}

gitinit() {
  if ! command -v git >/dev/null 2>&1; then
    __error "git not found in PATH"
    return 1
  fi

  if [ -z "$1" ]; then
    echo "Usage: gitinit <project-name>"
    return 1
  fi

  mkdir -p "$1" && cd "$1" || return 1
  git init

  cat > .gitignore << EOF
# Dependencies
node_modules/
.venv/
venv/
env/

# Build outputs
dist/
build/
*.egg-info/

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Environment variables
.env
.env.local

# Cache
.cache/
__pycache__/
*.pyc
EOF

  cat > README.md << EOF
# $1

## Description
Brief description of your project.

## Installation
\`\`\`bash
# Installation steps
\`\`\`

## Usage
\`\`\`bash
# Usage examples
\`\`\`

## Contributing
Pull requests are welcome.
EOF

  git add .
  git commit -m "Initial commit" 2>/dev/null || __warn "Commit skipped (configure git user.name/email to auto-commit)."

  echo "✅ Git repository '$1' initialized with basic structure!"
}

# --------------------------------------------------------------------------
# killport: Cross-platform port killer
# --------------------------------------------------------------------------
# Kill process listening on a port. Adapts to OS-specific tools.
# Usage: killport <port-number>
killport() {
  if [ -z "$1" ]; then
    echo "Usage: killport <port-number>"
    return 1
  fi

  local port=$1
  local pid=""
  local os=$(__detect_os)

  case "$os" in
    linux)
      # Try lsof first (most reliable)
      if command -v lsof >/dev/null 2>&1; then
        pid=$(lsof -ti:"$port" 2>/dev/null | head -n1)
      fi

      # Fallback to ss if lsof not available or found nothing
      if [ -z "$pid" ] && command -v ss >/dev/null 2>&1; then
        pid=$(ss -ltnp 2>/dev/null | awk -v P=":$port" '$4 ~ P {
          match($0, /pid=[0-9]+/);
          if (RSTART) print substr($0, RSTART+4, RLENGTH-4)
        }' | head -n1)
      fi
      ;;

    macos)
      # macOS: lsof is standard and most reliable
      if command -v lsof >/dev/null 2>&1; then
        pid=$(lsof -ti:"$port" 2>/dev/null | head -n1)
      fi

      # Fallback to netstat parsing (less reliable)
      if [ -z "$pid" ]; then
        pid=$(netstat -anv | awk -v P=".$port " '$4 ~ P && $6 == "LISTEN" {
          match($9, /[0-9]+/);
          if (RSTART) print substr($9, RSTART, RLENGTH)
        }' | head -n1)
      fi
      ;;

    freebsd|openbsd|netbsd)
      # BSD: use sockstat
      if command -v sockstat >/dev/null 2>&1; then
        pid=$(sockstat -l -p "$port" 2>/dev/null | awk 'NR>1 {print $3}' | head -n1)
      fi

      # Fallback to lsof if available
      if [ -z "$pid" ] && command -v lsof >/dev/null 2>&1; then
        pid=$(lsof -ti:"$port" 2>/dev/null | head -n1)
      fi
      ;;

    *)
      __error "Unsupported operating system for killport"
      return 1
      ;;
  esac

  if [ -n "$pid" ]; then
    if kill -9 "$pid" 2>/dev/null; then
      echo "✅ Killed process on port $port (PID: $pid)"
    else
      __error "Failed to kill PID $pid (may need sudo)"
      return 1
    fi
  else
    echo "No process found listening on port $port"
    return 1
  fi
}