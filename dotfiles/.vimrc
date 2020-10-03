set nocompatible "vi compatibility
syntax on
set nowrap "scroll instead of one more line
set encoding=utf8
set cmdheight=2
set nobackup
set nowritebackup
set hidden
set updatetime=300
set shortmess+=c
set number "strings number
set ruler

if exists('+termguicolors')
  "let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  "let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

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
set showtabline=1

set clipboard+=unnamedplus "share clipboard with x11

set keymap=russian-jcukenwin
set iminsert=0
set imsearch=0
highlight lCursor guifg=NONE guibg=Cyan

" Install vim-plug automatically
set runtimepath^=~/.config/nvim runtimepath+=~/.config/nvim/after
let &packpath = &runtimepath

if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.config/nvim/plugged')
Plug 'LnL7/vim-nix'               "Nix highlights
Plug 'cespare/vim-toml'           "TOML highlights
Plug 'craigemery/vim-autotag'     "Automatic ctags
Plug 'de-vri-es/vim-urscript'     "URScript highlights
Plug 'dense-analysis/ale'         "Universal linter
Plug 'lyokha/vim-xkbswitch'       "When CMD mode switch to US kb
Plug 'majutsushi/tagbar'          "A tab with tags
Plug 'nanotech/jellybeans.vim'    "Color scheme
Plug 'neoclide/coc.nvim', {'branch': 'release'} "IntelliSense for vim
Plug 'preservim/nerdtree'         "A tab with filesystem
Plug 'taketwo/vim-ros'
Plug 'tpope/vim-fugitive'         "Use git from vim
Plug 'universal-ctags/ctags'
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

map gn :bn<CR>
map gp :bp<CR>
map gd :bd<CR>

map ZW :wqa<CR>
map ZA :qa!<CR>

colorscheme jellybeans

autocmd BufNewFile,BufRead *.v,*.vs set syntax=verilog
autocmd BufNewFile,BufRead *.launch set syntax=xml
"autocmd BufNewFile,BufRead *.urs,*.script set syntax=python
autocmd BufWritePre * %s/\s\+$//e

" update tags on save python files
autocmd BufWritePost *.py silent! !ctags -R --python-kinds=-i --languages=python 2&gt; /dev/null &amp;
set tags=./tags,tags;$HOME

" Configuration for 'vim-xkbswitch' plugin
let g:XkbSwitchEnabled = 1
let g:XkbSwitchNLayout = 'us'
set ttimeoutlen=50
let g:XkbSwitchSkipFt = [ 'nerdtree' ]
let g:XkbSwitchLib = $HOME.'/.nix-profile/lib/libxkbswitch.so'

" Toggle search highlight
"set hlsearch! "no highliting by default
nnoremap <F3> :set hlsearch!<CR>
