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

# General Workspace
tmux has-session -t ws
if [ $? != 0 ]
then
  tmux new-session -s ws -n ws -d
  tmux send-keys -t ws:ws 'cd ~/Workspace' C-m
fi

# Other Workspaces
if test -z "$SSH_CLIENT"
then

  # My servers
  tmux has-session -t remote
  if [ $? != 0 ]
  then
    tmux new-session -s remote -n hetzner -d
    tmux send-keys -t remote:hetzner 'moshs hetzner.khassanov.me'
    tmux new-window -n hbrz
    tmux send-keys -t remote:hbrz 'ssh hbrz.khassanov.me'
  fi

  # Airalab
  # tmux has-session -t airalab
  # if [ $? != 0 ]
  # then
  #   tmux new-session -s airalab -n citadel -d
  #   tmux send-keys -t airalab:citadel 'moshs root@citadel.aira.life'
  # fi

  # REMY Robotics 
  tmux has-session -t remy
  if [ $? != 0 ]
  then
    tmux new-session -s remy -n ws -d
    tmux send-keys -t remy:ws 'cd ~/Workspace/remy' C-m
  fi

  # CCAI
  tmux has-session -t ccai
  if [ $? != 0 ]
  then
    tmux new-session -s ccai -n ws -d
    tmux send-keys -t ccai:ws 'cd ~/Workspace/ccai' C-m
  fi

fi

# Background
tmux has-session -t bg
if [ $? != 0 ]
then
  if test -z "$SSH_CLIENT"
  then # localhost
    tmux new-session -s "b"g -n vpn -d
    tmux send-keys -t "bg":vpn 'sudo openvpn --config ~/airalab-vpn.conf'
    tmux new-window -n opt
    tmux send-keys -t "bg":opt 'cd /opt' C-m
  else # remote host
    tmux new-session -s "bg" -d
  fi
fi
