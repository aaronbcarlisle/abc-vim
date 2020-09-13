" ----------------------------------------------------- Start Up Settings ---- "

"  system prep
if has ("win32")
    set rtp+=$USERPROFILE/vimfiles/bundle/Vundle.vim
    call vundle#rc('$USERPROFILE/vimfiles/bundle/')

    set directory=$USERPROFILE/vimfiles/swap//
    set backupdir=$USERPROFILE/vimfiles/backup//
    set undodir=$USERPROFILE/vimfiles/undo//

    set clipboard=unnamed
    set shell=cmd

    " Gvim
    if has("gui_running")
        set guifont=Lucida_Console:h10
        set showtabline=0
        set guioptions-=m "remove menu bar
        set guioptions-=T "remove toolbar
    endif

elseif has ("unix")
    set rtp+=~/.vim/bundle/Vundle.vim
    call vundle#rc()

    set directory=~/.vim/swap//
    set backupdir=~/.vim/backup//
    set undodir=~/.vim/undo//

    set clipboard=unnamedplus
    set shell=/bin/sh
endif

" set the mapleader
let mapleader=','

" Syntax highlighing
syntax on

" Try to detect filetypes
filetype on

" set python max line width
set colorcolumn=80
highlight ColorColumn ctermbg=DarkGray

" Enable loading indent file for filetype
filetype plugin indent on

" turn on line numbers
set number

" autosource vim on save
augroup reload_vimrc " {
   autocmd!
   autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END " }

augroup filetypedetect
    au! BufRead,BufNewFile *.ms	setf maxscript
augroup END

" Additional python syntax highlighting
let python_highlight_all=1

" cursorline settings
set cursorline
highlight Cursorline cterm=None

let g:airline#extensions#tabline#tab_min_count = 2
let g:airline#extensions#tabline#buffer_min_count = 2

" -------------------------------------------------------- Basic Settings ---- "

" enable mouse mode
set mouse=a
" Make command line one line high
set ch=1
" Keep 3 lines when scrolling
set scrolloff=3
" Always set autoindenting on
set autoindent
" Turn off erroring and beeping
set noerrorbells
" Show title in console title bar
set title
" Don't jump to first character when paging
set nostartofline
" Start,indent,eol
set backspace=2
" Show matching <> (html mainly) as well
set matchpairs+=<:>
" Jump to matching brace immediately after insert
set showmatch
" Time vim will sit on the matching brace
set matchtime=3
" Abbreviate messages
set shortmess=atI
" Highlight search items
set hlsearch
" Tab complete commands
set wildmenu
" Complete from a Dictionary if possible
set complete+=,k
" List longest first. Don't know if I want this
set wildmode=list:longest,full
" Whoever wanted to modify a .pyc?
set wildignore+=*.pyc
set wildignore+=*.swp
" Commandline remembrance
set history=10000
" Give me lots of Undos
set undolevels=10000
" Let my cursor go everywhere
set virtualedit=all
" Search as I type
set incsearch
" Use the / instead of \
set shellslash
" No word wrap
set nowrap
" Settings for vim to remember stuff on startup :help viminfo
set viminfo='1000,h
" Always show status line
set laststatus=2
set statusline+=%F
" This removes the characters between split windows (and some other junk)
set fillchars="-"
" This allows vim to work with buffers much more liberally. So no warnings when switching modified buffers
set hidden
" Persistent undos
"set undofile
" What information to save when creating a session.
set sessionoptions=buffers,resize,winpos,winsize
" Setting the language to everything NOT American English.
set spelllang=en_gb,en_nx,en_au,en_ca
" Ensure that all my auto formatting is minimal
set formatoptions=""

if has("autocmd")
   " I've set up these groups at the recommendation of Steve Losh's
   " Learn Vimscript the Hardway
   augroup clear_whitespace
       " Automatically delete trailing white spaces
       autocmd!
       autocmd BufEnter,BufRead,BufWrite * silent! %s/[\r \t]\+$//
       autocmd BufEnter *.php :%s/[ \t\r]\+$//e
   augroup END

   augroup set_syntax
       " Set current directory to that of the opened files
       autocmd!
       autocmd BufEnter * silent! :syntax on
   augroup END

   augroup set_working_path
       " Set current directory to that of the opened files
       autocmd!
       autocmd BufEnter,BufWrite * silent! lcd %:p:h
   augroup END

   augroup set_filetypes
       " Set some filtype stuff up
       autocmd!
       autocmd BufRead,BufNewFile *.ma setf mel
       autocmd BufRead,BufNewFile SConstruct setf python
       autocmd BufRead,BufNewFile wscript setf python
       autocmd BufNewFile,BufRead *.z* setlocal filetype=zsh
   augroup END

   augroup set_tabbing
       " Filetype specific tabbing
       autocmd!
       autocmd FileType * setlocal ts=4 sts=4 sw=4 noexpandtab cindent
       autocmd FileType python,vim,vimrc setlocal ts=4 sts=4 sw=4 expandtab
   augroup END

   augroup set_text_width
       " Set default textwidth
       autocmd!
       autocmd BufEnter * let b:textwidth=80
       autocmd Filetype python let b:textwidth=79
   augroup END
endif

" Echo current file path and put in middle mouse buffer
noremap <Leader>f :let @*=expand('%:p')<CR>:echom @*<CR>

" folding settings
set foldmethod=indent   "fold based on indent
set foldnestmax=10      "deepest fold is 10 levels
set nofoldenable        "dont fold by default
set foldlevel=1         "this is just what i use

" ---------------------------------------------------------- Key Bindings ---- "

" some leader shortcuts
nnoremap <Leader>w :w!<CR>
nnoremap <Leader>q :q<CR>
nnoremap <Leader>v :vsplit<CR>
nnoremap <Leader>h :sp<CR>
" perforce checkout
nnoremap <Leader>p :!p4 edit %:t<CR>

" Clear highlights with spacebar
noremap <silent> <Space> :nohlsearch <CR>

" Allow me to scroll horizontally
noremap <silent> <leader>o 30zl
noremap <silent> <leader>i 30zh

" inoremap kj <es
noremap <leader>sy :if exists("g:syntax_on") <Bar> syntax off <Bar> else <Bar> syntax on <Bar> endif <CR>c>

"" Make j and k work the way you expect
nnoremap j gj
nnoremap k gk
vnoremap j gj
vnoremap k gk

" Navigation between windows
nnoremap <C-J> <C-W>j
nnoremap <C-K> <C-W>k
nnoremap <C-H> <C-W>h
nnoremap <C-L> <C-W>l

" Fast edit the .vimrc file using ,x
nnoremap <Leader>x :tabedit $MYVIMRC<CR>

" hotkey for running python
if has ("win32")
    nnoremap <Leader>e :!python %<CR>
    "nnoremap <Leader>e :!"C:/Program Files/Autodesk/Maya2016/bin/mayapy.exe" %<CR>
elseif has ("unix")
    nnoremap <Leader>e :!/usr/bin/env python %<CR>
endif

" Reselect visual block afte indent/outdent
vnoremap < <gv
vnoremap > >gv

" ------------------------------------------------------- Plugin Settings ---- "

" PlUGINS
Bundle 'scrooloose/nerdcommenter'
Bundle 'w0ng/vim-hybrid'
Bundle 'jlanzarotta/bufexplorer'
Bundle 'octol/vim-cpp-enhanced-highlight'
Bundle 'nvie/vim-flake8'

" Hybrid Theme
set t_Co=256
colorscheme molokai
set background=dark

" BufExplorer
nnoremap <Leader>bb :ToggleBufExplorer<CR>
let g:bufExplorerSplitHorzSize=1

" Flake8
let g:flake8_quickfix_height=15

" Octol
let g:cpp_class_scope_highlight=1
let g:cpp_experimental_template_highlight=1
