ABC Vim
================================

My personal Vim setup for Linux and Windows. Built and inspired from https://github.com/irrigger/ir-vim.

---

# Install
Vundle is included in the following install commands. If Vundle is already installed it'll move to installing the plugins in the `.vimrc` file after the initial clone and setup.

### Windows
    cd %USERPROFILE% && git clone https://github.com/abcarlisle/abc-vim.git vimfiles && move vimfiles\.vimrc .vimrc && git clone https://github.com/VundleVim/Vundle.vim.git %USERPROFILE%/vimfiles/bundle/Vundle.vim & vim +PluginInstall +qall 

### Linux
    cd ~ && git clone https://github.com/abcarlisle/abc-vim.git .vim && mv .vim/.vimrc ~ && git clone https://github.com/VundleVim/Vundle.vim.git .vim/bundle/Vundle.vim; vim +PluginInstall +qall

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
