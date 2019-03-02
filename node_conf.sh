#!/bin/bash

# https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally
if [ ! -e ~/.npm-global && command -v npm ];
then
  mkdir ~/.npm-global
  npm config set prefix '~/.npm-global'
  export PATH=~/.npm-global/bin:$PATH # should be in ~/.profile or analog
fi
