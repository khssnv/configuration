# Improved command not found prompt
# =================================
[[ -e /etc/zsh_command_not_found ]] && source /etc/zsh_command_not_found

# Nix
# ===
if [ -e /home/khassanov/.nix-profile/etc/profile.d/nix.sh ];
then
  source /home/khassanov/.nix-profile/etc/profile.d/nix.sh;
fi


# Autostart tmux sessions
# =======================
cd ~
tmux start-server

# Workspace
tmux has-session -t ws
if [ $? != 0 ]
then
  tmux new-session -s ws -n Workspace -d
  tmux send-keys -t ws:Workspace 'cd ~/Workspace' C-m
fi

# Background
tmux has-session -t bg
if [ $? != 0 ]
then
  if test -z "$SSH_CLIENT"
  then # localhost
    tmux new-session -s bg -n vpn -d
    tmux send-keys -t bg:vpn 'sudo openvpn --config ~/airalab-vpn.conf'
    tmux new-window -n opt
    tmux send-keys -t bg:opt 'cd /opt' C-m
  else # remote host
    tmux new-session -s bg -d
  fi
fi

# Remotes
if test -z "$SSH_CLIENT"
then

  # My own
  tmux has-session -t remote
  if [ $? != 0 ]
  then
    tmux new-session -s remote -n linode -d
    tmux send-keys -t remote:linode 'moshs linode.khassanov.me'
    tmux new-window -n ovh
    tmux send-keys -t remote:ovh 'moshs ovh.khassanov.me'
  fi

  # Airalab
  tmux has-session -t airalab
  if [ $? != 0 ]
  then
    tmux new-session -s airalab -n citadel -d
    tmux send-keys -t airalab:citadel 'moshs root@citadel.aira.life'
  fi
fi
