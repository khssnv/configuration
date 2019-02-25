export ZSH="/home/khassanov/.oh-my-zsh"

ZSH_THEME="bira"
# ZSH_THEME="robbyrussell"
# ZSH_THEME="wezm"

plugins=(
  git
)

source $ZSH/oh-my-zsh.sh
unsetopt no_match
unsetopt SHARE_HISTORY

alias tl="tmux ls"
alias ta="tmux a -t"
alias tn="tmux new -s"

moshs () {
    mosh "$@" -- screen -dR mosh-session
}

mosh-tmux () {
    mosh "$@" -- tmux new -ADs mosh-session
}

source /opt/ros/melodic/setup.zsh
#source /opt/ros/crystal/setup.zsh
export PATH="$HOME/.cargo/bin:$PATH"
export PATH=~/.npm-global/bin:$PATH
