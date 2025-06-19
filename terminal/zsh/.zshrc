# Install zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

VIRTUAL_ENV_DISABLE_PROMPT=1
zmodload zsh/parameter  # Needed to access jobstates variable
setopt promptsubst
PROMPT='$(prompt "${#jobstates}" "$?"): '

# Load completions
zinit light zsh-users/zsh-completions
autoload -Uz compinit && compinit
zinit cdreplay -q

# Add zsh plugins
zinit light Aloxaf/fzf-tab
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light z-shell/zsh-eza

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
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# custom fzf flags
# NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
zstyle ':fzf-tab:*' fzf-flags --ansi --color=bw --style=minimal

# Load custom aliases
source $HOME/.zshalias

# Set editor to neovim
export EDITOR='nvim'

#npm global extensions go here
export npm_config_prefix="$HOME/.local/share/npm"

# Extend path to
export PATH="$PATH:$HOME/.bin/:$HOME/.local/bin"	# user executables
export PATH="$PATH:$HOME/.cargo/bin"			# cargo packages
export PATH="$PATH:$HOME/.local/share/npm/bin"		# npm global packages

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
