# -----------------------------------------------------------------------------
# File:    01-environment.zsh
# Purpose: Environment variables and PATH setup for development host
# Maintainer: <Mango Habanero> <main@mango-habanero.dev>
# Created: 2025-09-01
# SPDX-License-Identifier: MIT
#
# Notes:
#  - Sets EDITOR, PAGER, PYTHON-related envs, PATH additions (e.g. ~/.local/bin).
#  - Avoid putting secrets here; use 99-secrets.zsh.example or a secrets manager.
#  - Keep idempotent: safe to source multiple times.
# -----------------------------------------------------------------------------

# text editor settings
export EDITOR='code --wait'
export VISUAL='code --wait'
export PAGER='less'

# python settings
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# N/B: enforce virtualenv for pip to avoid polluting global site-packages
# Use `pipx` or `uv` to install global tools instead (e.g. `pipx install black`)
export PIP_REQUIRE_VIRTUALENV=true
