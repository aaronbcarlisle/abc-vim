" -- Start Up Settings --

" turn off filetype and caomptaible for Vundle setup
set nocompatible
filetype off

" system prep for unix/windows platforms
if has ("win32")
    set rtp+=$USERPROFILE/vimfiles/bundle/Vundle.vim
    call vundle#rc('$USERPROFILE/vimfiles/bundle/')

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
    set rtp+=~/.vim/bundle/Vundle.vim
    call vundle#rc()

    " re-map swap, backup and undo directories
    set directory=~/.vim/swap//
    set backupdir=~/.vim/backup//
    set undodir=~/.vim/undo//

    " this ensures the cliboard buffer works with linux terminal
    set clipboard=unnamedplus
    set shell=/bin/sh
endif

" -- Vundle Setup --

call vundle#begin()

Plugin 'VundleVim/Vundle.vim'

" some helpful plugins
Plugin 'tpope/vim-fugitive'
Plugin 'scrooloose/nerdcommenter'
Plugin 'w0ng/vim-hybrid'
Plugin 'jlanzarotta/bufexplorer'
Plugin 'octol/vim-cpp-enhanced-highlight'
Plugin 'nvie/vim-flake8'
Plugin 'jiangmiao/auto-pairs'

call vundle#end()

" -- Basic Settings ---

" turn on filetype detection and syntax highlighting
filetype on
syntax on

" enable loading indent file for filetype
filetype plugin indent on

" set the mapleader to be comma ',' for faster keybinds
let mapleader=','

" set 80 for PEP8 and 120 for C++ and SDK APIs
set colorcolumn=80,120
highlight ColorColumn ctermbg=DarkGray

" turn on line numbers
set number

" autosource vim on save
augroup reload_vimrc
   autocmd!
   autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END

" detect maxscript files
augroup filetypedetect
    au! BufRead,BufNewFile *.ms	setf maxscript
augroup END

" cursorline settings
set cursorline
highlight Cursorline cterm=None

" enable mouse mode
set mouse=a

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

" tab complete commands
set wildmenu

" complete from a dictionary if possible
set complete+=,k

" ignore some file extensions
set wildignore+=*.pyc,*.autosave,*~,*.exr,*.png,*.gif,*.bcd,*.jpg,*.jpeg,*.mp4,*.pc2,*.aus,*.hip,*.abc,*.xcf,*.pdf,*.tgz,*.tar,*.gz

" increase history
set history=10000

" increase number of undos
set undolevels=10000

" set cursor to go everywhere
set virtualedit=all

" search while typing
set incsearch

" Use the / instead of \
set shellslash

" no word wrap
set nowrap

" remember vim history on startup
set viminfo='1000,h

" always show status line
set laststatus=2
set statusline+=%F


" this removes the characters between split windows
set fillchars="-"

" this allows vim to work with buffers much more liberally. So no warnings when switching modified buffers
set hidden

" Persistent undos
set undofile

" set information to save when creating a session
set sessionoptions=buffers,resize,winpos,winsize

" set the language to everything NOT American English.
set spelllang=en_gb,en_nx,en_au,en_ca

" ensure that all auto-formatting is minimal
set formatoptions=""

" these are set up at the recommendation of Steve Losh's 'Learn Vimscript the Hardway'
if has("autocmd")

   " automatically delete trailing white spaces
   augroup clear_whitespace
       autocmd!
       autocmd BufEnter,BufRead,BufWrite * silent! %s/[\r \t]\+$//
       autocmd BufEnter *.php :%s/[ \t\r]\+$//e
   augroup END

   " set current directory to that of the opened files
   augroup set_syntax
       autocmd!
       autocmd BufEnter * silent! :syntax on
   augroup END

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
       autocmd BufNewFile,BufRead *.z* setlocal filetype=zsh
   augroup END

   " filetype specific tabbing
   augroup set_tabbing
       autocmd!
       autocmd FileType * setlocal ts=4 sts=4 sw=4 noexpandtab cindent
       autocmd FileType python,vim,vimrc setlocal ts=4 sts=4 sw=4 expandtab
   augroup END

   " set default textwidth
   augroup set_text_width
       autocmd!
       autocmd BufEnter * let b:textwidth=80
       autocmd Filetype python let b:textwidth=79
   augroup END
endif

" echo current file path and put in middle mouse buffer
noremap <Leader>f :let @*=expand('%:p')<CR>:echom @*<CR>

" folding settings
set foldmethod=indent "fold based on indent
set foldnestmax=10 "deepest fold is 10 levels
set nofoldenable "dont fold by default
set foldlevel=1 "this is just what i use

" -- Key Bindings --

" write/quit keybinds
nnoremap <Leader>w :w!<CR>
nnoremap <Leader>q :q<CR>

" pane split keybinds
nnoremap <Leader>v :vsplit<CR>
nnoremap <Leader>h :sp<CR>

" clear highlights with spacebar
noremap <silent> <Space> :nohlsearch <CR>

" add keybind for horizontal scroll
noremap <silent> <leader>o 30zl
noremap <silent> <leader>i 30zh

" add keybind for syntax highlighting toggle
noremap <leader>sy :if exists("g:syntax_on") <Bar> syntax off <Bar> else <Bar> syntax on <Bar> endif <CR>c>

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
nnoremap <Leader>x :tabedit $MYVIMRC<CR>

" fast install Plugins
nnoremap <Leader>p :PluginInstall<CR>

" setup Python execution hotkey
if has ("win32")
    nnoremap <Leader>e :!python %<CR>
elseif has ("unix")
    nnoremap <Leader>e :!/usr/bin/env python %<CR>
endif

" reselect visual block after indent/outdent
vnoremap < <gv
vnoremap > >gv

" modify and set the hybrid colorscheme
set t_Co=256
set background=dark
colorscheme hybrid

nnoremap <Leader>bb :ToggleBufExplorer<CR>

" -- Plugin Settings --

" Additional python syntax highlighting
let python_highlight_all=1

" set bufexplorer keybinds
let g:bufExplorerSplitHorzSize=1

" set octol settings for C++
let g:cpp_class_scope_highlight=1
let g:cpp_experimental_template_highlight=1
