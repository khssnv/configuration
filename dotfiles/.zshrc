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

source /etc/os-release

case $NAME in
  "NixOS");;
  "Ubuntu")
    source ~/.nix-profile/etc/profile.d/nix.sh # nix
    export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH # home-manager
  ;;
esac

# source $ZSH/oh-my-zsh.sh
unsetopt no_match
unsetopt SHARE_HISTORY

HOSTNAME=`hostname`

# echo "Hostname is $HOSTNAME"
if [ "$HOSTNAME" = "gs75" ]; then
    source /opt/ros/melodic/setup.zsh
elif [ "$HOSTNAME" = "pizza-pc" ]; then
    ROS_DISTRO=melodic
    source /opt/ros/$ROS_DISTRO/setup.zsh
    source /home/khassanov/Workspace/REMY_Robotics/Pizza_Restaurant/pizza_restaurant/devel/setup.zsh
fi

if [ ! -S ~/.ssh/ssh_auth_sock ] && [ -S "$SSH_AUTH_SOCK" ]; then
    ln -sf $SSH_AUTH_SOCK ~/.ssh/ssh_auth_sock
fi

# PROMPT='${ret_status}%{$fg_bold[green]%}%p %{$fg[cyan]%}%c %{$fg_bold[blue]%}$(git_prompt_info)%{$fg_bold[blue]%} %D %T % %{$reset_color%}'
# export LANG=en_US.UTF-8
# export LC_ALL=en_US.UTF-8
export SUDO_EDITOR=$(which nvim)

alias ipython="ipython --profile=myprofile"
alias ccy="catkin clean -y"
alias tl="tmux ls"
alias ta="tmux a -t"
alias tn="tmux new -s"
alias c="xclip -selection clipboard"
alias v="xclip -o"
alias cbpy3="catkin build --cmake-args \
-DCMAKE_CXX_STANDARD=17 \
-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
-DCMAKE_BUILD_TYPE=RelWithDebInfo \
-DPYTHON_EXECUTABLE=/usr/bin/python3 \
-DPYTHON_INCLUDE_DIR=/usr/include/python3.6m \
-DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.6m.so"
alias cbc="catkin build clean -y"

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


# temporary solution for Z shell agent forwarding issue
# without it I have `SSH_AUTH_SOCK=/run/user/1001/gnupg/S.gpg-agent.ssh`
# instead of `SSH_AUTH_SOCK=/tmp/ssh-wpIvELmtyl/agent.3250` for some reason.
# Solution took from:
# https://superuser.com/questions/141044/sharing-the-same-ssh-agent-among-multiple-login-sessions

function sshagent_findsockets {
    find /tmp -uid $(id -u) -type s -name agent.\* 2>/dev/null
}

function sshagent_testsocket {
    if [ ! -x "$(which ssh-add)" ] ; then
        echo "ssh-add is not available; agent testing aborted"
        return 1
    fi

    if [ X"$1" != X ] ; then
        export SSH_AUTH_SOCK=$1
    fi

    if [ X"$SSH_AUTH_SOCK" = X ] ; then
        return 2
    fi

    if [ -S $SSH_AUTH_SOCK ] ; then
        ssh-add -l > /dev/null
        if [ $? = 2 ] ; then
            echo "Socket $SSH_AUTH_SOCK is dead!  Deleting!"
            rm -f $SSH_AUTH_SOCK
            return 4
        else
            echo "Found ssh-agent $SSH_AUTH_SOCK"
            return 0
        fi
    else
        echo "$SSH_AUTH_SOCK is not a socket!"
        return 3
    fi
}

function sshagent_init {
    # ssh agent sockets can be attached to a ssh daemon process or an
    # ssh-agent process.

    AGENTFOUND=0

    # Attempt to find and use the ssh-agent in the current environment
    # if sshagent_testsocket ; then AGENTFOUND=1 ; fi

    # If there is no agent in the environment, search /tmp for
    # possible agents to reuse before starting a fresh ssh-agent
    # process.
    if [ $AGENTFOUND = 0 ] ; then
        for agentsocket in $(sshagent_findsockets) ; do
            if [ $AGENTFOUND != 0 ] ; then break ; fi
            if sshagent_testsocket $agentsocket ; then AGENTFOUND=1 ; fi
        done
    fi

    # If at this point we still haven't located an agent, it's time to
    # start a new one
    if [ $AGENTFOUND = 0 ] ; then
        eval `ssh-agent`
    fi

    # Clean up
    unset AGENTFOUND
    unset agentsocket

    # Finally, show what keys are currently in the agent
    ssh-add -l
}

alias sagent="sshagent_init"
