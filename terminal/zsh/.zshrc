# Install zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

VIRTUAL_ENV_DISABLE_PROMPT=1
zmodload zsh/parameter  # Needed to access jobstates variable
setopt promptsubst
PROMPT='$(prompt "${#jobstates}" "$?"): '

# Add zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light z-shell/zsh-eza

# Add oh-my-zsh plugins
zinit snippet OMZP::archlinux
zinit snippet OMZP::colored-man-pages

# Load completions
autoload -Uz compinit && compinit
zinit cdreplay -q

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always --icons $realpath'


# Load custom aliases
source $HOME/.zshalias

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='nvim'
fi

#npm global extensions go here
export npm_config_prefix="$HOME/.local/share/npm"

# Extend path to
export PATH="$PATH:$HOME/.bin/"				# user executables
export PATH="$PATH:$HOME/.local/bin"			# user executables
export PATH="$PATH:$HOME/.cargo/bin"			# cargo packages
export PATH="$PATH:$HOME/.local/share/npm/bin"		# npm global packages
export PATH="$PATH:$HOME/.deno/bin/"			# deno

# Enable sccache
export RUSTC_WRAPPER=/usr/bin/sccache

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

