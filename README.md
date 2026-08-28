# ABC Vim

My personal Vim setup for Linux, macOS, and Windows. Inspired by
[irrigger/ir-vim](https://github.com/irrigger/ir-vim).

## Install

The installers are idempotent; re-running one is also how you update. Each
installs any missing dependencies (`git`, `vim`), puts the vim files in place,
points `~/.vimrc` and `~/.ideavimrc` at them, and installs Vundle plus the
plugins listed in the `.vimrc`.

|              | Linux / macOS | Windows                     |
| ------------ | ------------- | --------------------------- |
| Vim files go | `~/.vim`      | `%USERPROFILE%\vimfiles`    |
| Installer    | `install.sh`  | `install.ps1`               |

### Linux / macOS

Download the installer (inspect it if you like), then run it:

```sh
curl -fsSL https://raw.githubusercontent.com/aaronbcarlisle/abc-vim/master/install.sh -o abc-vim-install.sh
sh abc-vim-install.sh
```

Or clone first and install from the clone:

```sh
git clone https://github.com/aaronbcarlisle/abc-vim.git ~/.vim
sh ~/.vim/install.sh
```

### Windows (PowerShell)

```powershell
iwr -useb https://raw.githubusercontent.com/aaronbcarlisle/abc-vim/master/install.ps1 -OutFile abc-vim-install.ps1
powershell -ExecutionPolicy Bypass -File abc-vim-install.ps1
```

Or clone first and install from the clone:

```powershell
git clone https://github.com/aaronbcarlisle/abc-vim.git $env:USERPROFILE\vimfiles
powershell -ExecutionPolicy Bypass -File $env:USERPROFILE\vimfiles\install.ps1
```

### Notes

- **Run from a checkout and it installs that working tree**, uncommitted edits
  included, instead of cloning the remote. Downloaded standalone, it clones.
- **Nothing is overwritten.** An abc-vim checkout already at the install path is
  updated with `git pull --ff-only`; anything else there — plus any existing
  `~/.vimrc` or `~/.ideavimrc` — is moved aside to a timestamped `.bak` first.
- **Dependencies** are installed with whichever package manager is on `PATH`
  (`apt`/`dnf`/`yum`/`pacman`/`zypper`/`apk`/`brew`/`port` on Unix,
  `winget`/`choco`/`scoop` on Windows). If none is found, the installer names
  the missing dependency and stops.
- **Windows symlinks** need Developer Mode or an admin shell. Without them the
  installer copies the config files instead, and edits to those copies will not
  track the repo.
- Set `ABC_VIM_REPO` to install from a fork.

## Credits

Plugins, managed by [Vundle](https://github.com/VundleVim/Vundle.vim):

- [jlanzarotta/bufexplorer](https://github.com/jlanzarotta/bufexplorer)
- [jiangmiao/auto-pairs](https://github.com/jiangmiao/auto-pairs)
- [nvie/vim-flake8](https://github.com/nvie/vim-flake8)
- [octol/vim-cpp-enhanced-highlight](https://github.com/octol/vim-cpp-enhanced-highlight)
- [preservim/nerdcommenter](https://github.com/preservim/nerdcommenter)
- [tpope/vim-fugitive](https://github.com/tpope/vim-fugitive)

The [w0ng/vim-hybrid](https://github.com/w0ng/vim-hybrid) colorscheme is
vendored directly as `colors/hybrid.vim`, so it works before Vundle has run.
