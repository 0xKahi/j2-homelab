let mapleader = ' '
let maplocalleader = ' '

filetype on
filetype plugin on
filetype indent on
syntax on

" Disable compatibility with vi which can cause unexpected issues.
set nocompatible

set number
set relativenumber

set title
set showcmd
set nowrap

set smarttab
set expandtab
set tabstop=2
set softtabstop=2
set shiftwidth=2
set autoindent
set breakindent

set ignorecase
set smartcase

set gdefault
set notimeout
set timeoutlen=5000
set showmode

set fileencoding=utf-8 " the encoding written to a file

set nohlsearch
set incsearch

set termguicolors
set colorcolumn=

set scrolloff=8

set splitbelow
set splitright

" Cursor shapes per mode (Linux console)
let &t_EI = "\033[6 q" " Normal mode: steady block cursor (2)
let &t_SI = "\033[4 q" " Insert mode: steady bar cursor (6)
let &t_SR = "\033[2 q" " Replace mode: steady underline cursor (4)

inoremap kj <ESC>

nnoremap U <C-r>

" File explorer
nnoremap <leader>pv :Ex<CR>

xnoremap <leader>p "_dP
nnoremap <leader>d "_d
vnoremap <leader>d "_d

" Buffer navigation
nmap ]b :bnext<CR>
nmap [b :bprev<CR>
nmap <leader>bd :bdelete<CR>

" Window navigation
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l
