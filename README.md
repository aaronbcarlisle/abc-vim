Vim Setup
================================

Personal Vim setup for both Linux and Windows built and inspired from https://github.com/irrigger/ir-vim.

# Installation

## Windows

    git clone https://github.com/abcarlisle/vim.git %USERPROFILE%\vimfiles && move %USERPROFILE%\vimfiles\.vimrc %USERPROFILE%\.vimrc && git clone https://github.com/VundleVim/Vundle.vim.git %USERPROFILE%/vimfiles/bundle/Vundle.vim && vim -c ":PluginInstall | q"

## Linux

    git clone https://github.com/abcarlisle/vim.git ~/.vim && mv ~/.vim/.vimrc ~ && git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim && vim -c ":PluginInstall | q"

