ABC Vim
================================

My personal Vim setup for Linux and Windows. Built and inspired from https://github.com/irrigger/ir-vim.

---

# Install
The installers are idempotent and safe to re-run. They install any missing
dependencies (`git`, `vim`), clone the vim files, set up `~/.vimrc`, install
Vundle, and then install the plugins listed in the `.vimrc`. Existing
directories are handled gracefully — an existing abc-vim checkout is updated in
place, anything else (or an existing `~/.vimrc`) is backed up with a timestamp
rather than overwritten.

### Linux / macOS
One-line bootstrap (no clone needed):

    sh -c "$(curl -fsSL https://raw.githubusercontent.com/aaronbcarlisle/abc-vim/master/install.sh)"

Or from a local clone:

    git clone https://github.com/aaronbcarlisle/abc-vim.git ~/.vim && sh ~/.vim/install.sh

### Windows (PowerShell)
One-line bootstrap (no clone needed):

    iwr -useb https://raw.githubusercontent.com/aaronbcarlisle/abc-vim/master/install.ps1 | iex

Or from a local clone:

    git clone https://github.com/aaronbcarlisle/abc-vim.git $env:USERPROFILE\vimfiles; powershell -ExecutionPolicy Bypass -File $env:USERPROFILE\vimfiles\install.ps1

> Dependency auto-install uses your system package manager
> (`apt`/`dnf`/`yum`/`pacman`/`zypper`/`apk`/`brew`/`port` on Unix,
> `winget`/`choco`/`scoop` on Windows). If none is available the installer tells
> you which dependency to install by hand.

---

# Contributions
- [jlanzarotta/bufexplorer](https://github.com/jlanzarotta/bufexplorer)
- [jiangmiao/auto-pairs](https://github.com/jiangmiao/auto-pairs)
- [irrigger/ir-vim](https://github.com/irrigger/ir-vim)
- [nvie/vim-flake8](https://github.com/nvie/vim-flake8)
- [octol/vim-cpp-enhanced-highlight](https://github.com/octol/vim-cpp-enhanced-highlight)
- [preservim/nerdcommenter](https://github.com/preservim/nerdcommenter)
- [tpope/vim-fugitive](https://github.com/tpope/vim-fugitive)
- [VundleVim/Vundle.vim](https://github.com/VundleVim/Vundle.vim)
- [w0ng/vim-hybrid](https://github.com/w0ng/vim-hybrid)
