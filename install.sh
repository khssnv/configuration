#!/bin/sh

cp -rf ./.zshrc ~
cp -rf ./.zprofile ~
cp -rf ./.vimrc ~
cp -rf ./.gitconfig ~

# VIM Vundle
if [ -e ~/.vim/bundle/Vundle.vim ];
then
  git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
  vim +PluginInstall +qall
fi
