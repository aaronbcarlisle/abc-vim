#!/usr/bin/env sh
# ============================================================================
# ABC Vim - Unix/Linux/macOS installer
#
# Usage (from a clone):  sh install.sh
# Usage (download first, inspect, then run -- preferred over piping to a shell):
#   curl -fsSL https://raw.githubusercontent.com/aaronbcarlisle/abc-vim/master/install.sh -o abc-vim-install.sh
#   less abc-vim-install.sh   # optional: review before running
#   sh abc-vim-install.sh
#
# This script is idempotent and safe to re-run. It will:
#   1. Install missing dependencies (git, vim) using your package manager.
#   2. Clone (or update) the abc-vim files into ~/.vim.
#   3. Link ~/.vimrc to the tracked config.
#   4. Install (or update) Vundle.
#   5. Install the plugins listed in the .vimrc.
# ============================================================================

set -eu

REPO_URL="${ABC_VIM_REPO:-https://github.com/aaronbcarlisle/abc-vim.git}"
VUNDLE_URL="https://github.com/VundleVim/Vundle.vim.git"
VIM_DIR="$HOME/.vim"
VIMRC="$HOME/.vimrc"
VUNDLE_DIR="$VIM_DIR/bundle/Vundle.vim"

# --- pretty logging --------------------------------------------------------
info() { printf '\033[0;32m[abc-vim]\033[0m %s\n' "$1"; }
warn() { printf '\033[0;33m[abc-vim]\033[0m %s\n' "$1" >&2; }
err()  { printf '\033[0;31m[abc-vim]\033[0m %s\n' "$1" >&2; }

stamp() { date +%Y%m%d%H%M%S; }
have()  { command -v "$1" >/dev/null 2>&1; }

# --- dependency installation -----------------------------------------------
# Picks whatever package manager is available. Uses sudo only when not root.
install_pkg() {
    pkg="$1"
    SUDO=""
    [ "$(id -u)" -ne 0 ] && have sudo && SUDO="sudo"

    if   have apt-get; then $SUDO apt-get update && $SUDO apt-get install -y "$pkg"
    elif have dnf;     then $SUDO dnf install -y "$pkg"
    elif have yum;     then $SUDO yum install -y "$pkg"
    elif have pacman;  then $SUDO pacman -S --noconfirm "$pkg"
    elif have zypper;  then $SUDO zypper install -y "$pkg"
    elif have apk;     then $SUDO apk add "$pkg"
    elif have brew;    then brew install "$pkg"
    elif have port;    then $SUDO port install "$pkg"
    else
        err "No supported package manager found. Please install '$pkg' manually and re-run."
        return 1
    fi
}

ensure_dep() {
    if have "$1"; then
        return 0
    fi
    warn "'$1' is not installed - attempting to install it..."
    if install_pkg "$1" && have "$1"; then
        info "Installed '$1'."
    else
        err "Could not install '$1'. Aborting."
        exit 1
    fi
}

ensure_dep git
ensure_dep vim

# --- clone or update the vim files -----------------------------------------
if [ -d "$VIM_DIR/.git" ]; then
    info "$VIM_DIR already exists - updating it instead of re-cloning."
    git -C "$VIM_DIR" pull --ff-only || warn "Could not fast-forward $VIM_DIR; leaving it as-is."
elif [ -e "$VIM_DIR" ]; then
    # Something is already at ~/.vim but it is not an abc-vim checkout.
    backup="$VIM_DIR.bak.$(stamp)"
    warn "$VIM_DIR exists but is not an abc-vim git checkout - moving it to $backup"
    mv "$VIM_DIR" "$backup"
    git clone "$REPO_URL" "$VIM_DIR"
else
    git clone "$REPO_URL" "$VIM_DIR"
fi

# Make sure the runtime scratch directories used by the .vimrc exist.
mkdir -p "$VIM_DIR/swap" "$VIM_DIR/backup" "$VIM_DIR/undo" "$VIM_DIR/bundle"

# --- link ~/.vimrc ---------------------------------------------------------
TARGET_VIMRC="$VIM_DIR/.vimrc"
if [ ! -f "$TARGET_VIMRC" ]; then
    err "Expected $TARGET_VIMRC to exist after clone but it is missing. Aborting."
    exit 1
fi

if [ -L "$VIMRC" ]; then
    # Already a symlink - just repoint it.
    ln -sf "$TARGET_VIMRC" "$VIMRC"
elif [ -e "$VIMRC" ]; then
    backup="$VIMRC.bak.$(stamp)"
    warn "Existing $VIMRC found - backing it up to $backup"
    mv "$VIMRC" "$backup"
    ln -s "$TARGET_VIMRC" "$VIMRC"
else
    ln -s "$TARGET_VIMRC" "$VIMRC"
fi
info "Linked $VIMRC -> $TARGET_VIMRC"

# --- install or update Vundle ----------------------------------------------
if [ -d "$VUNDLE_DIR/.git" ]; then
    info "Vundle already installed - updating it."
    git -C "$VUNDLE_DIR" pull --ff-only || warn "Could not fast-forward Vundle; leaving it as-is."
elif [ -e "$VUNDLE_DIR" ]; then
    backup="$VUNDLE_DIR.bak.$(stamp)"
    warn "$VUNDLE_DIR exists but is not a git checkout - moving it to $backup"
    mv "$VUNDLE_DIR" "$backup"
    git clone "$VUNDLE_URL" "$VUNDLE_DIR"
else
    git clone "$VUNDLE_URL" "$VUNDLE_DIR"
fi

# --- install the plugins ---------------------------------------------------
info "Installing plugins via Vundle..."
if vim +PluginInstall +qall; then
    info "All done! Start vim to enjoy your ABC Vim setup."
else
    err "Vim exited non-zero during plugin installation. Re-run 'vim +PluginInstall' to retry."
    exit 1
fi
