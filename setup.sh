#!/usr/bin/env bash
set -euo pipefail

# =======================================
# cromarchy post-install linker script
# ---------------------------------------
# PURPOSE:
#   Take files from:
#     1) common/                 (applies to all devices)
#     2) hosts/<HOSTNAME>/       (device-specific overrides)
#   …and link them into $HOME, backing up any existing *real* files.
#
# MENTAL MODEL (ASCII):
#
#     +-------------------+         +-------------------+
#     |   common/ tree    |         |  hosts/$HOSTNAME/ |
#     |  (shared configs) |         | (device overrides)|
#     +----------+--------+         +---------+---------+
#                \                           /
#                 \  link into $HOME        /
#                  \     (symlinks)        /
#                   v                      v
#                 ~/.config/... (first)  (then overrides)
#
#   Precedence:
#       host file > common file
#
#   Example:
#       common/.config/hypr/hyprland.conf           -> ~/.config/hypr/hyprland.conf
#       hosts/DESKTOP-CRAIG/.config/hypr/monitors.conf (overrides common if present)
#
# USAGE:
#   ./setup.sh
#
# REQUIREMENTS:
#   - Run from repo root OR anywhere (script resolves its own dir).
#   - Host dir name must match: `hostnamectl --static` (fallback: `hostname`).
#
# BACKUPS:
#   If a destination exists and is a *real file* (not a symlink),
#   it is copied to: <path>.bak.YYYY-MM-DD-HHMMSS, then replaced by the symlink.
# =======================================

# Resolve repo dir (works even if invoked from elsewhere)
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Detect short hostname for hosts/<HOSTNAME>/
HOSTNAME_SHORT="$(hostnamectl --static 2>/dev/null || hostname 2>/dev/null || echo default)"

# Simple logger
log() { printf "%b\n" "[$(date +%H:%M:%S)] $*"; }

# ---------------------------------------
# link_file
# ---------------------------------------
# $1 = source (absolute path inside repo)
# $2 = dest   (absolute path in $HOME)
#
# Ensures parent dir, backs up real files, creates/updates symlink.
link_file() {
  local src="$1" dst="$2"

  mkdir -p "$(dirname "$dst")"

  # Backup any existing non-symlink file/dir
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    cp -an "$dst" "${dst}.bak.$(date +%F-%H%M%S)"
    rm -rf "$dst"
  fi

  # Create or refresh the symlink (atomic-ish update)
  ln -sfn "$src" "$dst"
  log "🔗 Linked $dst -> $src"
}

# ---------------------------------------
# link_tree_with_override
# ---------------------------------------
# $1 = path to common dir
# $2 = path to host-specific dir
#
# Links all files from common first, then overlays host files.
link_tree_with_override() {
  local base="$1" override="$2" homedir="$HOME"

  # 1) common → $HOME
  if [ -d "$base" ]; then
    (cd "$base" && find . -type f -print0) |
      while IFS= read -r -d '' f; do
        link_file "$base/$f" "$homedir/$f"
      done
  else
    log "ℹ️  No common dir at: $base"
  fi

  # 2) hosts/<HOSTNAME> → $HOME (overrides)
  if [ -d "$override" ]; then
    (cd "$override" && find . -type f -print0) |
      while IFS= read -r -d '' f; do
        link_file "$override/$f" "$homedir/$f"
      done
  else
    log "⚠️  No host dir for '$HOSTNAME_SHORT' (looked in: $override)"
  fi
}

# =======================================
# MAIN
# =======================================
log "🔧 cromarchy: linking dotfiles (common + hosts/$HOSTNAME_SHORT)"
link_tree_with_override "$REPO_DIR/common" "$REPO_DIR/hosts/$HOSTNAME_SHORT"
log "✅ Done"
