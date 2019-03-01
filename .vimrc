" syntax highlight
syntax on
set nocompatible              "be iMproved, required
filetype off                  "required

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
set shiftwidth=2                "An indent is 2 spaces
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
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'               "Vim plugin manager, https://github.com/VundleVim/Vundle.vim
Plugin 'Valloric/YouCompleteMe'             "Code autocompleter, https://github.com/Valloric/YouCompleteMe
Plugin 'taketwo/vim-ros'                    "From https://github.com/taketwo/vim-ros
"Plugin 'udalov/javap-vim'                   "Java decompiler from https://github.com/udalov/javap-vim
Plugin 'aklt/plantuml-syntax'               "PlantUML syntax
"Plugin 'scrooloose/vim-slumlord'           "Live preview of PlantUML diagrams, https://github.com/scrooloose/vim-slumlord
"Plugin 'fatih/vim-go'                      "Necessary for 'vim-slumlord' plugin
Plugin 'weirongxu/plantuml-previewer.vim'   "Browser PlantUML preview https://github.com/weirongxu/plantuml-previewer.vim
Plugin 'tyru/open-browser.vim'              "Necessary for 'plantuml-previewer.vim'
Plugin 'tomlion/vim-solidity'               "Ethereum Solidity syntax highlight, https://github.com/tomlion/vim-solidity
Plugin 'nanotech/jellybeans.vim'            "Color scheme https://github.com/nanotech/jellybeans.vim
Plugin 'pangloss/vim-javascript'            "JavaScript
Plugin 'mxw/vim-jsx'                        "React JSX
Plugin 'Yggdroot/indentLine'                "Point indents
Plugin 'ElmCast/elm-vim'                    "Elm
Plugin 'w0rp/ale'                           "Linter
Plugin 'mattn/emmet-vim'                    "HTML and CSS
Plugin 'LnL7/vim-nix'
call vundle#end()            "required
filetype plugin indent on    "required
let g:pydiction_location='~/.vim/tools/pydiction/complete-dict'
" Vundle block end


" Elm
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:elm_syntastic_show_warnings = 1
let g:ycm_semantic_triggers = {
     \ 'elm' : ['.'],
     \}
