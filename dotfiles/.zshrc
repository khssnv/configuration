source /etc/os-release
unsetopt no_match
unsetopt SHARE_HISTORY
# PROMPT='${ret_status}%{$fg_bold[green]%}%p %{$fg[cyan]%}%c %{$fg_bold[blue]%}$(git_prompt_info)%{$fg_bold[blue]%} %D %T % %{$reset_color%}'
# export LANG=en_US.UTF-8
# export LC_ALL=en_US.UTF-8

# Vim is default editor
export VISUAL=vim
export EDITOR="$VISUAL"
export SUDO_EDITOR=$(which nvim)

# OS specific
case $NAME in
  "NixOS");;
  "Ubuntu")
    source ~/.nix-profile/etc/profile.d/nix.sh # nix
    export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH # home-manager
  ;;
esac

# Host specific
HOSTNAME=`hostname`
if [ "$HOSTNAME" = "gs75" ]; then
    source /opt/ros/melodic/setup.zsh
elif [ "$HOSTNAME" = "pizza-pc" ]; then
    ROS_DISTRO=melodic
    source /opt/ros/$ROS_DISTRO/setup.zsh
    source /home/khassanov/Workspace/REMY_Robotics/Pizza_Restaurant/pizza_restaurant/devel/setup.zsh
fi

# Aliases
alias ipython="ipython --profile=myprofile"
alias tl="tmux ls"
alias ta="tmux a -t"
alias tn="tmux new -s"
alias c="xclip -selection clipboard"
alias v="xclip -o"
alias ccy="catkin clean -y"
alias cbc="catkin build clean -y"
alias cbpy3="catkin build --cmake-args \
-DCMAKE_CXX_STANDARD=17 \
-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
-DCMAKE_BUILD_TYPE=RelWithDebInfo \
-DPYTHON_EXECUTABLE=/usr/bin/python3 \
-DPYTHON_INCLUDE_DIR=/usr/include/python3.6m \
-DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.6m.so"
alias rosne="source /opt/ros/noetic/setup.zsh"
alias ros2fe="source /opt/ros/foxy/setup.zsh && source /usr/share/colcon_cd/function/colcon_cd.sh"
alias zsh_hide_git="git config --add oh-my-zsh.hide-status 1 \
&& git config --add oh-my-zsh.hide-dirty 1"

# moshs () {
#     mosh "$@" -- screen -dR alisher
# }
#
# mosh-tmux () {
#     mosh "$@" -- tmux new -ADs mosh-session
# }

# SSH agent
# temporary solution for Z shell agent forwarding issue
# without it I have `SSH_AUTH_SOCK=/run/user/1001/gnupg/S.gpg-agent.ssh`
# instead of `SSH_AUTH_SOCK=/tmp/ssh-wpIvELmtyl/agent.3250` for some reason.
# Solution took from:
# https://superuser.com/questions/141044/sharing-the-same-ssh-agent-among-multiple-login-sessions

if [ ! -S ~/.ssh/ssh_auth_sock ] && [ -S "$SSH_AUTH_SOCK" ]; then
    ln -sf $SSH_AUTH_SOCK ~/.ssh/ssh_auth_sock
fi

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
