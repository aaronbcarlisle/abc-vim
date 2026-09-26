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
#   2. Clone (or update) the abc-vim files into ~/.vim (or update an
#      existing checkout in ~/vimfiles).
#   3. Link ~/.vimrc to the tracked config.
#   4. Install (or update) Vundle.
#   5. Install (and update) the plugins listed in the .vimrc.
# ============================================================================

set -eu

REPO_URL="${ABC_VIM_REPO:-https://github.com/aaronbcarlisle/abc-vim.git}"
VUNDLE_URL="https://github.com/VundleVim/Vundle.vim.git"
VIM_DIR="$HOME/.vim"
VIMRC="$HOME/.vimrc"
IDEAVIMRC="$HOME/.ideavimrc"

# On Windows, install.ps1 installs to ~/vimfiles instead, and the .vimrc finds
# either. If that is where the existing abc-vim checkout lives, update it
# rather than creating a second copy in ~/.vim.
if [ ! -d "$VIM_DIR/.git" ] && [ -d "$HOME/vimfiles/.git" ] && \
   [ -f "$HOME/vimfiles/colors/hybrid.vim" ]; then
    VIM_DIR="$HOME/vimfiles"
fi
VUNDLE_DIR="$VIM_DIR/bundle/Vundle.vim"

# --- pretty logging --------------------------------------------------------
info() { printf '\033[0;32m[abc-vim]\033[0m %s\n' "$1"; }
warn() { printf '\033[0;33m[abc-vim]\033[0m %s\n' "$1" >&2; }
err()  { printf '\033[0;31m[abc-vim]\033[0m %s\n' "$1" >&2; }

stamp() { date +%Y%m%d%H%M%S; }
have()  { command -v "$1" >/dev/null 2>&1; }

# Git Bash / MSYS2 / Cygwin: a plain `ln -s` silently makes a *copy* there, so
# ~/.vimrc would drift from the repo. Ask for a real Windows symlink (works
# with Developer Mode or an admin shell); nativestrict makes ln fail instead of
# copying, so link_file can say what actually happened.
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        export MSYS="${MSYS:+$MSYS }winsymlinks:nativestrict"
        export CYGWIN="${CYGWIN:+$CYGWIN }winsymlinks:nativestrict"
        ;;
esac

# link_file TARGET LINK - symlink LINK to TARGET, or copy when not allowed.
link_file() {
    if ln -s "$1" "$2" 2>/dev/null; then
        info "Linked $2 -> $1"
    else
        cp "$1" "$2"
        warn "Symlinks unavailable - copied $1 to $2 instead (edits in $2 will not track the repo; enable Windows Developer Mode and re-run to link)."
    fi
}

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

# --- locate a local checkout -----------------------------------------------
# If this script is being run from inside an abc-vim git checkout, install from
# that working tree (picking up local/uncommitted edits) instead of cloning the
# remote. When piped/downloaded standalone, fall back to the remote clone.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" 2>/dev/null && pwd -P) || SCRIPT_DIR=""
LOCAL_SRC=""
if [ -n "$SCRIPT_DIR" ]; then
    src_top=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null) || src_top=""
    # Git for Windows prints C:/Users/..., while $HOME is /c/Users/... under
    # Git Bash: canonicalize so the in-place check below sees the same dir
    # (otherwise it tries to move the checkout it is running from).
    [ -n "$src_top" ] && src_top=$(CDPATH='' cd -- "$src_top" 2>/dev/null && pwd -P) || true
    # Require markers specific to abc-vim, not just any repo with a root .vimrc,
    # so we never recursively copy an unrelated dotfiles/home tree into ~/.vim.
    if [ -n "$src_top" ] && [ -f "$src_top/.vimrc" ] && \
       [ -f "$src_top/colors/hybrid.vim" ] && [ -f "$src_top/install.ps1" ]; then
        LOCAL_SRC="$src_top"
    fi
fi

# --- clone, copy, or update the vim files ----------------------------------
VIM_DIR_REAL=""
[ -d "$VIM_DIR" ] && VIM_DIR_REAL=$(CDPATH='' cd -- "$VIM_DIR" && pwd -P)

if [ -n "$LOCAL_SRC" ] && [ "$LOCAL_SRC" = "$VIM_DIR_REAL" ]; then
    info "Running from the canonical checkout at $VIM_DIR - updating it in place."
    git -C "$VIM_DIR" pull --ff-only || warn "Could not fast-forward $VIM_DIR; leaving it as-is."
elif [ -n "$LOCAL_SRC" ]; then
    info "Installing from local checkout $LOCAL_SRC"
    if [ -e "$VIM_DIR" ]; then
        backup="$VIM_DIR.bak.$(stamp)"
        warn "$VIM_DIR already exists - moving it to $backup"
        mv "$VIM_DIR" "$backup"
    fi
    # copy the working tree verbatim (including .git) so uncommitted edits are
    # preserved and future 'git pull' updates still work.
    cp -a "$LOCAL_SRC" "$VIM_DIR"
elif [ -d "$VIM_DIR/.git" ]; then
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
    rm -f "$VIMRC"
elif [ -e "$VIMRC" ]; then
    backup="$VIMRC.bak.$(stamp)"
    warn "Existing $VIMRC found - backing it up to $backup"
    mv "$VIMRC" "$backup"
fi
link_file "$TARGET_VIMRC" "$VIMRC"

# --- link ~/.ideavimrc (IdeaVim support) -----------------------------------
TARGET_IDEAVIMRC="$VIM_DIR/.ideavimrc"
if [ -f "$TARGET_IDEAVIMRC" ]; then
    if [ -L "$IDEAVIMRC" ]; then
        rm -f "$IDEAVIMRC"
    elif [ -e "$IDEAVIMRC" ]; then
        backup="$IDEAVIMRC.bak.$(stamp)"
        warn "Existing $IDEAVIMRC found - backing it up to $backup"
        mv "$IDEAVIMRC" "$backup"
    fi
    link_file "$TARGET_IDEAVIMRC" "$IDEAVIMRC"
fi

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
info "Installing and updating plugins via Vundle..."
if vim +PluginUpdate +qall > /dev/null 2>&1; then
    info "All done! Start vim to enjoy your ABC Vim setup."
else
    err "Vim exited non-zero during plugin installation. Re-run 'vim +PluginUpdate' to retry."
    exit 1
fi
