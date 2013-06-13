set shiftwidth=4
set expandtab
set tabstop=4

set wildmenu
set wcm=<Tab>
menu Encoding.koi8-r :e ++enc=koi8-r ++ff=unix<CR>
menu Encoding.windows-1251 :e ++enc=cp1251 ++ff=dos<CR>
menu Encoding.cp866 :e ++enc=cp866 ++ff=dos<CR>
menu Encoding.utf-8 :e ++enc=utf8 <CR>
menu Encoding.koi8-u :e ++enc=koi8-u ++ff=unix<CR>
map <F8> :emenu Encoding.<TAB>

:set number
:syntax on
:colorscheme desert
:set noignorecase
:set nocursorline

:hi Error guifg=NONE guibg=NONE gui=undercurl ctermfg=white ctermbg=red cterm=NONE guisp=#FF6c60

" disabling compat mode
set nocompatible

" set default UTF-8
set encoding=utf-8

" start pluginloader
call pathogen#infect()
filetype plugin indent on

" setup color scheme
colorscheme wombat256mod
syntax on

" enabling line numbers
set number
highlight LineNr ctermfg=Yellow

" enabling cursorline
set cursorline

" enabling statusline
set laststatus=2

" disabling backup
set nobackup

" set history len
set history=100

" set TAB space
set tabstop=4
set softtabstop=4

" set TAB to SPACE conversion
set expandtab
