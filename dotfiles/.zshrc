if [[ ":$FPATH:" != *":/home/khassanov/.zsh/completions:"* ]]; then export FPATH="/home/khassanov/.zsh/completions:$FPATH"; fi
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="ys"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	docker
	docker-compose
	# dotenv
	git
	history-substring-search
	# ipfs
	kubectl
	man
	# poetry
	# pyenv # invokes `pyenv init` which we don't want
	vagrant
	# virtualenvwrapper
	# zsh-syntax-highlighting
	nvm
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Custom config

export PATH="/home/$USER/.local/bin:$PATH"

# Alias
# =====

alias c="xclip -selection clipboard"
alias v="xclip -o"
alias ledger-bridge="npx --no-install ledger-live proxy -v"
alias mybadger="/home/khassanov/Workspace/github.com/khssnv/badger/badger/badger"

alias tx401off="echo 1 | sudo tee /sys/bus/pci/devices/0000:83:00.0/remove"
alias tx401on="echo 1 | sudo tee /sys/bus/pci/rescan"

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Functions
# =========

# Abbriviate long names in path
function felix_pwd_abbr {
	base_pwd=$PWD
	tilda_notation=${base_pwd//$HOME/\~}
	pwd_list=(${(s:/:)tilda_notation})
	list_len=${#pwd_list}

	if [[ $list_len -le 1 ]]; then
		echo $tilda_notation
		return
	fi

	if [[ ${pwd_list[1]} != '~' ]]; then
		formed_pwd='/'
	fi

	firstchar=$(echo ${pwd_list[1]} | cut -c1)
	if [[ $firstchar == '.' ]] ; then
		firstchar=$(echo ${pwd_list[1]} | cut -c1,2)
	fi

	formed_pwd=${formed_pwd}$firstchar

	for ((i=2; i <= $list_len; i++)) do
		if [[ $i != ${list_len} ]]; then

			firstchar=$(echo ${pwd_list[$i]} | cut -c1)
			if [[ $firstchar == '.' ]] ; then
				firstchar=$(echo ${pwd_list[$i]} | cut -c1,2)
			fi

			formed_pwd=${formed_pwd}/$firstchar
		else
			formed_pwd=${formed_pwd}/${pwd_list[$i]}
		fi
	done

	echo $formed_pwd
	return
}

# Dprint
# ======

export DPRINT_INSTALL="/home/khassanov/.dprint"
export PATH="$DPRINT_INSTALL/bin:$PATH"

# Python
# ======

export PYTHONUNBUFFERED=1

## pyenv
# export PYENV_ROOT="$HOME/.pyenv"
# [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"

## Poetry
# export PATH="$HOME/.poetry/bin:$PATH"

## pip
# export PATH="$PATH:/home/khassanov/.local/bin"

# ## virtualenvwrapper
# # export WORKON_HOME=$HOME/.virtualenvs
# # export PROJECT_HOME=$HOME/Workspace
# # source /usr/local/bin/virtualenvwrapper.sh
# 
# # >>> conda initialize >>>
# # !! Contents within this block are managed by 'conda init' !!
# __conda_setup="$('/home/khassanov/.miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
# if [ $? -eq 0 ]; then
#     eval "$__conda_setup"
# else
#     if [ -f "/home/khassanov/.miniconda3/etc/profile.d/conda.sh" ]; then
#         . "/home/khassanov/.miniconda3/etc/profile.d/conda.sh"
#     else
#         export PATH="/home/khassanov/.miniconda3/bin:$PATH"
#     fi
# fi
# unset __conda_setup
# # <<< conda initialize <<<

# Rust
# ====

source "$HOME/.cargo/env"
export PATH="$HOME/.cargo/bin:$PATH"

# sccache
# export RUSTC_WRAPPER=sccache
# export SCCACHE_CACHE_SIZE="100G"

# Go
# ==

export GOPATH=$HOME/.go
# export GOTOOLCHAIN="auto"
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOPATH/bin:/usr/local/go/bin

# JavaScript
# ==========

# nvm
# ---
# This is done by oh-my-zsh plugin.
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# alias yarn="nvm exec yarn"
# alias npm="nvm exec npm

# # Espressif
# # =========
# alias get_idf="export IDF_PATH=$HOME/Workspace/esp/esp-idf/ && \
#   export IDF_PYTHON_ENV_PATH=$HOME/.espressif/python_env/idf4.4_py3.8_env && \
# # source $HOME/.espressif/python_env/idf4.4_py3.8_env/bin/activate && \  # commented out by conda initialize
#   source $HOME/Workspace/esp/esp-idf/export.sh"
# export IDF_PATH="$HOME/Workspace/esp/esp-idf/"
# export PATH="$IDF_PATH/tools/:$PATH"
# export PATH="$HOME/esp/xtensa-esp32-elf/bin:$PATH"
# 
# # Guix
# # ====
# export GUIX_LOCPATH="$HOME/.guix-profile/lib/locale"
# source "$GUIX_PROFILE/etc/profile"
 
# Solana
# ======

export PATH="/home/khassanov/.local/share/solana/install/active_release/bin:$PATH"
 
# # ROS Noetic
# # ==========
# source /opt/ros/noetic/setup.zsh
# 
# # ROS2 Rolling
# # ==========
# source /opt/ros/rolling/setup.zsh
# source /opt/ros/rolling/share/ros2cli/environment/ros2-argcomplete.zsh
# # source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.zsh
# # source /usr/share/colcon_cd/function/colcon_cd.sh
# export ROS_DOMAIN_ID=1
# export ROS_LOCALHOST_ONLY=1
# # export _colcon_cd_root=~/ros2_install

# Kubernetes Flux2
# ================
# command -v flux >/dev/null && . <(flux completion zsh) && compdef _flux flux

# Kubernetes Krew
# ===============
# https://krew.sigs.k8s.io/
# export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
 
# # JetBrains
# # =========
# alias webstorm="/home/khassanov/.local/share/JetBrains/Toolbox/apps/WebStorm/ch-0/211.7442.26/bin/webstorm.sh"
 
# # JetBrans IDEs terminal Alt+key
# bindkey "\e\eC" backward-word
# bindkey "\e\eD" forward-word

# emscripten
# ==========

# source "/home/khassanov/Workspace/github.com/emscripten-core/emsdk/emsdk_env.sh" > /dev/null 2>&1

# GitHub
# ======

# export GITHUB_TOKEN=""
# export GITHUB_USER="khssnv"
 
# GitHub CLI
# ==========

autoload -U compinit
compinit -i

# Mosh
# ====

export LC_ALL=en_US.UTF-8
 
# Filecoin
# ========

alias lotus="lotus-filecoin.lotus"

# Asciinema
# =========

alias asciicast2gif='docker run --rm -v $PWD:/data asciinema/asciicast2gif --'
 
# kubo ipfs
# =========
#
# completions
# eval "$(ipfs commands completion bash)"

# Haskell
# =======

[ -f "/home/khassanov/.ghcup/env" ] && source "/home/khassanov/.ghcup/env" # ghcup-env
# export IHP_EDITOR="code --goto"

# MerkleBot
# =========

alias mbneton="sudo systemctl start wg-quick@wg0"
alias mbnetoff="sudo systemctl stop wg-quick@wg0"
alias mbnetstatus="sudo systemctl status wg-quick@wg0"

# Cere Network
# ============

alias cere-login=""
alias twingate-install="curl -s https://binaries.twingate.com/client/linux/install.sh | sudo bash"
alias twingate-purge="sudo apt purge twingate"

# eval "$(direnv hook zsh)"

# bun
# ===
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# bun completions
[ -s "/home/khassanov/.bun/_bun" ] && source "/home/khassanov/.bun/_bun"

# Java, Kotlin
# ============

JAVA_HOME=~/.jdks/openjdk-22.0.1
export PATH=$PATH:$JAVA_HOME/bin
export JAVA_HOME

M2_HOME='/opt/apache-maven-3.9.6'
export PATH="$M2_HOME/bin:$PATH"

# Add JBang to environment
alias j!=jbang
export PATH="$HOME/.jbang/bin:$PATH"

# Cosmos SDK
# ==========
# eval $(ignite completion zsh)

# Zig
# ===

export ZIG_INSTALL="/home/khassanov/.config/Code/User/globalStorage/ziglang.vscode-zig/zig_install"
export PATH="$ZIG_INSTALL:$PATH"

export ZLS_INSTALL="/home/khassanov/.config/Code/User/globalStorage/ziglang.vscode-zig/zls_install"
export PATH="$ZLS_INSTALL:$PATH"

# Risc0
# =====

export PATH="$PATH:/home/khassanov/.risc0/bin"

# Vscode
# ======

if [ "$TERM_PROGRAM" = "vscode" ]; then
    git config --global core.editor "code --wait"
fi

# Terraform
# =========

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/bin/terraform terraform

# Deno
# ====

. "/home/khassanov/.deno/env"

