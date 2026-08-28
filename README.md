# ABC Vim

My personal Vim setup for Linux, macOS, and Windows. Inspired by
[irrigger/ir-vim](https://github.com/irrigger/ir-vim).

## Install

The installers are idempotent, so you can run them multiple times to update. Each installer will:
- Install any missing dependencies (git and vim)
- Set up your vim files in the appropriate location
- Configure ~/.vimrc and ~/.ideavimrc to point to the setup
- Install Vundle and all plugins listed in your .vimrc

|              | Linux / macOS | Windows                     |
| ------------ | ------------- | --------------------------- |
| Vim files go | `~/.vim`      | `%USERPROFILE%\vimfiles`    |
| Installer    | `install.sh`  | `install.ps1`               |

### Linux / macOS

**Option 1: Download and run the installer**

```sh
curl -fsSL https://raw.githubusercontent.com/aaronbcarlisle/abc-vim/master/install.sh -o abc-vim-install.sh
sh abc-vim-install.sh
```

**Option 2: Clone first, then install from your local copy**

```sh
git clone https://github.com/aaronbcarlisle/abc-vim.git ~/.vim
sh ~/.vim/install.sh
```

### Windows (PowerShell)

**Option 1: Download and run the installer**

```powershell
iwr -useb https://raw.githubusercontent.com/aaronbcarlisle/abc-vim/master/install.ps1 -OutFile abc-vim-install.ps1
powershell -ExecutionPolicy Bypass -File abc-vim-install.ps1
```

**Option 2: Clone first, then install from your local copy**

```powershell
git clone https://github.com/aaronbcarlisle/abc-vim.git $env:USERPROFILE\vimfiles
powershell -ExecutionPolicy Bypass -File $env:USERPROFILE\vimfiles\install.ps1
```

### How the installer works

- **Installing from a local checkout**: If you run the installer from a cloned repository, it installs from that local copy (including any uncommitted changes). If you download the installer standalone, it clones the remote repository instead.
- **Safe file handling**: Existing files are never overwritten. If abc-vim is already installed, it updates with `git pull --ff-only`. Any other existing files, including ~/.vimrc or ~/.ideavimrc, are moved to a timestamped .bak file first.
- **Package manager detection**: Dependencies are installed using whatever package manager is available on your system (apt, dnf, yum, pacman, zypper, apk, brew, or port on Unix; winget, choco, or scoop on Windows). If no package manager is found, the installer will stop and let you know what's missing.
- **Windows symlinks**: Creating symlinks on Windows requires Developer Mode or an admin shell. If these aren't available, the installer copies the config files instead. Note that edits to copied files won't sync with the repository.
- **Custom fork installation**: Set the `ABC_VIM_REPO` environment variable to install from your own fork.

## Credits

Plugins, managed by [Vundle](https://github.com/VundleVim/Vundle.vim):

- [jlanzarotta/bufexplorer](https://github.com/jlanzarotta/bufexplorer)
- [jiangmiao/auto-pairs](https://github.com/jiangmiao/auto-pairs)
- [nvie/vim-flake8](https://github.com/nvie/vim-flake8)
- [octol/vim-cpp-enhanced-highlight](https://github.com/octol/vim-cpp-enhanced-highlight)
- [preservim/nerdcommenter](https://github.com/preservim/nerdcommenter)
- [tpope/vim-fugitive](https://github.com/tpope/vim-fugitive)
- [w0ng/vim-hybrid](https://github.com/w0ng/vim-hybrid) (also vendored as `colors/hybrid.vim`)
