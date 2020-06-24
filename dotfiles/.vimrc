set nocompatible "vi compatibility
syntax on
set nowrap "scroll instead of one more line
set encoding=utf8

" strings number
set number
set ruler

if exists('+termguicolors')
  "let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  "let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

set rtp+=~/.vim/bundle/jellybeans.vim
colorscheme jellybeans
set backspace=indent,eol,start

set laststatus=2

" set TAB space
set tabstop=2
set softtabstop=2
set shiftwidth=2                "an indent is 2 spaces
set smarttab                    "indent instead of tab at start of line
set shiftround                  "round spaces to nearest shiftwidth multiple
set nojoinspaces                "don't convert spaces to tabs
set expandtab                   "convert tabs to spaces
let g:indentLine_setConceal = 0
set showtabline=0

set keymap=russian-jcukenwin
set iminsert=0
set imsearch=0
highlight lCursor guifg=NONE guibg=Cyan

" Install vim-plug automatically
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
Plug 'dense-analysis/ale'         "Universal linter
Plug 'taketwo/vim-ros'
Plug 'LnL7/vim-nix'

" Utility
Plug 'preservim/nerdtree'
Plug 'majutsushi/tagbar'
call plug#end()

" ALE linter
"let g:ale_enabled = 0
let g:ale_lint_on_save = 0
let g:ale_lint_on_text_changed = 'never' 
"let g:ale_lint_on_enter = 0
let g:ale_sign_column_always = 1
let g:ale_linters_explicit = 1 "Only run linters named in ale_linters settings
let g:ale_linters = {
\   'cpp': ['gcc', 'cpplint'],
\   'javascript': ['eslint'],
\   'python': ['flake8'],
\}
let g:ale_sign_error = '●'
let g:ale_sign_warning = '.'
" Enable / disable linting by Ctrl-l
nmap <C-l> :ALEToggle<CR>
"highlight clear ALEErrorSign
"highlight clear ALEWarningSign
"packloadall
"silent! helptags ALL

" Specials for C-family
let g:ycm_clangd_binary_path = "/usr/bin/clangd" "YouCompleteMe for C-family

" vim-ros
let g:ycm_semantic_triggers = {
\   'roslaunch' : ['="', '$(', '/'],
\   'rosmsg,rossrv,rosaction' : ['re!^', '/'],
\ }

map <C-n> :NERDTreeToggle<CR>
map <C-m> :TagbarToggle<CR>
