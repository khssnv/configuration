#!/usr/bin/env bash

DOTFILES_DIR="$( cd $( dirname ${BASH_SOURCE[0]} ) >/dev/null 2>&1 && pwd )"

cp -rf ./.zshrc ~
cp -rf ./.zlogin ~
cp -rf ./.vimrc ~
cp -rf ./.gitconfig ~
cp -rf ./.tmux.conf ~
# cp -rf ./.yank.sh ~
cp -rf ./.npmrc  ~

# VIM Vundle
if [ ! -e ~/.vim/bundle/Vundle.vim ];
then
  git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
  vim +PluginInstall +qall
fi
