export ZSH="/home/khassanov/.oh-my-zsh"

ZSH_THEME="bira"
# ZSH_THEME="robbyrussell"
# ZSH_THEME="wezm"

plugins=(
  git
)

source $ZSH/oh-my-zsh.sh
unsetopt SHARE_HISTORY
alias tl="tmux ls"
alias ta="tmux a -t"
alias tn="tmux new -s"

source /opt/ros/melodic/setup.zsh
export PATH="$HOME/.cargo/bin:$PATH"
export PATH=~/.npm-global/bin:$PATH
