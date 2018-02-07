" syntax highlight
syntax on

" strings number
set number
highlight LineNr ctermfg=Yellow

set laststatus=2

" set TAB space
set tabstop=2
set softtabstop=2
set shiftwidth=4                "An indent is 2 spaces
set smarttab                    "Indent instead of tab at start of line
set shiftround                  "Round spaces to nearest shiftwidth multiple
set nojoinspaces                "Don't convert spaces to tabs
set expandtab                   "set TAB to SPACE conversion

" disable tabline
set showtabline=0

set keymap=russian-jcukenwin
set iminsert=0
set imsearch=0
highlight lCursor guifg=NONE guibg=Cyan

" Vundle block begin
set nocompatible              " be iMproved, required
filetype off                  " required

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'   " Installation https://github.com/VundleVim/Vundle.vim
Plugin 'Valloric/YouCompleteMe' " Installation https://github.com/Valloric/YouCompleteMe

call vundle#end()            " required
filetype plugin indent on    " required
" Vundle block end
