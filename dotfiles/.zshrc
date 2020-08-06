# export ZSH="/home/khassanov/.oh-my-zsh"

# ZSH_THEME="bira"
# ZSH_THEME="robbyrussell"
# ZSH_THEME="wezm"

# plugins=(
#   ssh-agent
#   git
# )

# zstyle :omz:plugins:ssh-agent agent-forwarding on
# zstyle :omz:plugins:ssh-agent identities id_ed25519
# zstyle :omz:plugins:ssh-agent lifetime 4h

# source $ZSH/oh-my-zsh.sh
unsetopt no_match
unsetopt SHARE_HISTORY

# PROMPT='${ret_status}%{$fg_bold[green]%}%p %{$fg[cyan]%}%c %{$fg_bold[blue]%}$(git_prompt_info)%{$fg_bold[blue]%} %D %T % %{$reset_color%}'
# export LANG=en_US.UTF-8
# export LC_ALL=en_US.UTF-8
export SUDO_EDITOR=$(which nvim)

alias tl="tmux ls"
alias ta="tmux a -t"
alias tn="tmux new -s"
alias c="xclip -selection clipboard"
alias v="xclip -o"

# moshs () {
#     mosh "$@" -- screen -dR alisher
# }
# 
# mosh-tmux () {
#     mosh "$@" -- tmux new -ADs mosh-session
# }

# ROS1_ENV="/opt/ros/melodic/setup.zsh"
# ROS2_ENV="/opt/ros/dashing/setup.zsh"
# if [ -e "$ROS1_ENV" ]; then
#   source $ROS1_ENV
# elif [ -e $ROS2_ENV ]; then
#   source $ROS2_ENV
# fi

# CARGO_BIN="$HOME/.cargo/bin"
# if [ -d $CARGO_BIN ]; then
#   export PATH="$CARGO_BIN:$PATH"
# fi
# 
# NPM_HOME="$HOME/.npm-global/bin"
# if [ -d $NPM_HOME ]; then
#   export PATH="$NPM_HOME:$PATH"
# fi
