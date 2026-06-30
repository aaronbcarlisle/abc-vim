" -- Start Up Settings ---

" turn off filetype and compatible for Vundle setup
set nocompatible
filetype off

" system prep for unix/windows platforms
if has ("win32")
    " re-map swap, backup and undo directories
    set directory=$USERPROFILE/vimfiles/swap//
    set backupdir=$USERPROFILE/vimfiles/backup//
    set undodir=$USERPROFILE/vimfiles/undo//

    set clipboard=unnamed
    set shell=cmd

    " set some default gvim settings
    if has("gui_running")
        set guifont=Lucida_Console:h10
        set showtabline=0
        set guioptions-=m "remove menu bar
        set guioptions-=T "remove toolbar
    endif

elseif has ("unix")
    " re-map swap, backup and undo directories
    set directory=~/.vim/swap//
    set backupdir=~/.vim/backup//
    set undodir=~/.vim/undo//

    " this ensures the clipboard buffer works with linux terminal
    set clipboard=unnamedplus
    set shell=/bin/sh
endif


if !has ("pycharm")
    " -- Vundle Setup --

    " add Vundle to the runtimepath and point it at the platform's bundle dir.
    " expand() is required so $USERPROFILE resolves (Vimscript strings are
    " not environment-expanded on their own).
    " guard the rtp+= so re-sourcing $MYVIMRC on save does not stack duplicate
    " Vundle paths onto 'runtimepath'.
    if has ("win32")
        if &runtimepath !~# 'vimfiles[\\/]bundle[\\/]Vundle\.vim'
            set rtp+=$USERPROFILE/vimfiles/bundle/Vundle.vim
        endif
        call vundle#begin(expand('$USERPROFILE/vimfiles/bundle/'))
    else
        if &runtimepath !~# '\.vim/bundle/Vundle\.vim'
            set rtp+=~/.vim/bundle/Vundle.vim
        endif
        call vundle#begin()
    endif

    " some useful plugins
    Plugin 'jlanzarotta/bufexplorer'
    Plugin 'jiangmiao/auto-pairs'
    Plugin 'nvie/vim-flake8'
    Plugin 'octol/vim-cpp-enhanced-highlight'
    Plugin 'preservim/nerdcommenter'
    Plugin 'tpope/vim-fugitive'
    Plugin 'w0ng/vim-hybrid'

    call vundle#end()
endif

" -- Basic Settings ---

" set encoding
set encoding=utf-8
set fileencoding=utf-8

" turn on filetype detection and syntax highlighting
syntax on
filetype on

" enable loading indent file for filetype
filetype plugin indent on

" set the mapleader to be comma ',' for faster keybinds
let mapleader=','

" set 80 for PEP8 and 120 for C++ and SDK APIs
set colorcolumn=80,120
highlight ColorColumn ctermbg=DarkGray

" turn on line numbers (with relative line numbers for easier movement)
set number
set relativenumber

" autosource vim on save
augroup reload_vimrc
   autocmd!
   autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END

" cursorline settings
set cursorline
highlight Cursorline cterm=None

" enable mouse mode
set mouse=a

" Cursor shape configuration for different modes (console/terminal)
" This makes the cursor change shape based on the mode you're in
if !has("gui_running")
    " Insert mode - vertical bar (thin line cursor)
    let &t_SI = "\e[6 q"
    " Replace mode - underline cursor
    let &t_SR = "\e[4 q"
    " Normal mode - block cursor (full block)
    let &t_EI = "\e[2 q"

    " Reset cursor when exiting vim
    augroup RestoreCursor
        autocmd!
        autocmd VimLeave * let &t_me="\e[0 q"
    augroup END
endif

" make command line one line high
set ch=1

" keep 3 lines when scrolling
set scrolloff=3

" always set autoindenting on
set autoindent

" turn off error bells
set noerrorbells

" show title in console title bar
set title

" don't jump to first character when paging
set nostartofline

" set backspace character value
set backspace=2

" show matching <> (html mainly) as well
set matchpairs+=<:>

" jump to matching brace immediately after insert
set showmatch

" time vim will sit on the matching brace
set matchtime=3

" abbreviate messages
set shortmess=atI

" highlight search items
set hlsearch

" completion setup (add dictionary completion)
set complete+=k
" point 'k' completion at a system word list when available; on Windows there
" is no standard location so it silently falls back to runtimepath word files.
if !has("win32") && filereadable('/usr/share/dict/words')
    set dictionary+=/usr/share/dict/words
endif

" tab completion
set wildmenu
set wildmode=longest,list,full

" ignore setup
set wildignorecase
set wildignore+=*.pyc,*.autosave,*~,*.exr,*.png,*.gif,*.bcd,*.jpg,*.jpeg,*.mp4,*.pc2,*.aus,*.hip,*.abc,*.xcf,*.pdf,*.tgz,*.tar,*.gz

" increase history
set history=10000

" increase number of undos
set undolevels=10000

" set cursor to go everywhere
set virtualedit=all

" search while typing
set incsearch

" smart case-insensitive search (case-insensitive unless capital letter used)
set ignorecase
set smartcase

" Use the / instead of \ (Windows only; has no effect on Unix and errors in
" some builds when set unconditionally)
if has("win32")
    set shellslash
endif

" no word wrap
set nowrap

" remember vim history on startup
set viminfo='1000,h

" always show status line with useful information
set laststatus=2
set statusline=%F%m%r%h%w\ [%{&ff}]\ [%Y]\ [%p%%]\ [Line:\ %l/%L,\ Col:\ %c]

" this removes the characters between split windows (use vert for vertical splits)
set fillchars=vert:\ ,fold:-

" this allows vim to work with buffers so no warnings when switching modified buffers
set hidden

" Persistent undos
set undofile

" set information to save when creating a session
set sessionoptions=buffers,resize,winpos,winsize

" set the language to everything NOT American English.
set spelllang=en_gb,en_au,en_ca

" ensure that all auto-formatting is minimal
set formatoptions=

" these are set up at the recommendation of Steve Losh's 'Learn Vimscript the Hardway'
if has("autocmd")

   " automatically delete trailing white spaces on save (BufWritePre only, so
   " merely opening or switching buffers never edits them or jumps the cursor)
   augroup clear_whitespace
       autocmd!
       autocmd BufWritePre * let b:ws_view = winsaveview() |
           \ silent! keeppatterns %s/[\r \t]\+$// |
           \ call winrestview(b:ws_view)
   augroup END

   " (syntax is already enabled globally via 'syntax on' near the top; a
   " BufEnter autocmd that re-ran it would undo the ,sy / :syntax off toggle.)

   " set current directory to that of the opened files
   augroup set_working_path
       autocmd!
       autocmd BufEnter,BufWrite * silent! lcd %:p:h
   augroup END

   " set some filtype stuff up
   augroup set_filetypes
       autocmd!
       autocmd BufRead,BufNewFile *.ma setf mel
       autocmd BufRead,BufNewFile SConstruct setf python
       autocmd BufRead,BufNewFile wscript setf python
       autocmd BufNewFile,BufRead *.zsh,.zshrc,.zshenv,.zprofile,.zlogin,.zlogout setlocal filetype=zsh
   augroup END

   " filetype specific tabbing
   augroup set_tabbing
       autocmd!
       autocmd FileType * setlocal ts=4 sts=4 sw=4 noexpandtab cindent
       autocmd FileType python,vim,vimrc setlocal ts=4 sts=4 sw=4 expandtab
   augroup END

   " set default textwidth (80 everywhere, 79 for Python). Use the real
   " 'textwidth' option via setlocal -- b:textwidth was just an unused variable,
   " and a global default avoids BufEnter clobbering the Python-specific value.
   set textwidth=80
   augroup set_text_width
       autocmd!
       autocmd FileType python setlocal textwidth=79
   augroup END
endif

" echo current file path and put in middle mouse buffer
noremap <Leader>f :let @*=expand('%:p')<CR>:echom @*<CR>

" folding settings
set foldmethod=indent "fold based on indent
set foldnestmax=10 "deepest fold is 10 levels
set nofoldenable "dont fold by default
set foldlevel=1 "this is just what i use

" -- Key Bindings ---

" write/quit keybinds
nnoremap <Leader>w :w!<CR>
nnoremap <Leader>q :q<CR>
nnoremap <Leader>bd :bd<CR>

" pane split keybinds
nnoremap <Leader>v :vsplit<CR>
nnoremap <Leader>h :sp<CR>

" clear highlights with spacebar
noremap <silent> <Space> :nohlsearch <CR>

" add keybind for horizontal scroll
noremap <silent> <leader>o 30zl
noremap <silent> <leader>i 30zh

" add keybind for syntax highlighting toggle
noremap <leader>sy :if exists("g:syntax_on") <Bar> syntax off <Bar> else <Bar> syntax on <Bar> endif <CR>

" toggle relative line numbers
nnoremap <leader>rn :set relativenumber!<CR>

" make j and k to be more vim like
nnoremap j gj
nnoremap k gk
vnoremap j gj
vnoremap k gk

" setup navigation to be more Vim like
nnoremap <C-J> <C-W>j
nnoremap <C-K> <C-W>k
nnoremap <C-H> <C-W>h
nnoremap <C-L> <C-W>l

" fast edit the .vimrc file using ,x
nnoremap <Leader>x :e ~/.vimrc<CR>

" setup Python execution hotkey
if has ("win32")
    nnoremap <Leader>e :!python %<CR>
elseif has ("unix")
    nnoremap <Leader>e :!/usr/bin/env python %<CR>
endif

" reselect visual block after indent/outdent
vnoremap < <gv
vnoremap > >gv

if !has ("pycharm")

    " fast install Plugins
    nnoremap <Leader>p :PluginInstall<CR>

    " modify and set the hybrid colorscheme
    set t_Co=256
    set background=dark
    silent! colorscheme hybrid

    " set keybind for bufexplorer toggle
    nnoremap <Leader>bb :ToggleBufExplorer<CR>

    " -- Plugin Settings --

    " Additional python syntax highlighting
    let python_highlight_all=1

    " set bufexplorer keybinds
    let g:bufExplorerSplitHorzSize=1

    " set octol settings for C++
    let g:cpp_class_scope_highlight=1
    let g:cpp_experimental_template_highlight=1
endif
