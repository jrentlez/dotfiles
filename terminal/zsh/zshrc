# Install zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Prompt
zmodload zsh/parameter  # Needed to access jobstates variable
setopt promptsubst
export VIRTUAL_ENV_DISABLE_PROMPT=1
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
# Disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# Force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# Custom fzf flags
# NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
zstyle ':fzf-tab:*' fzf-flags --ansi --color=bw --style=minimal

# Set editor to neovim
export EDITOR='nvim'

# NPM global extensions go here
export npm_config_prefix="$HOME/.local/share/npm"

# Extend path to
export PATH="$PATH:$HOME/.bin/:$HOME/.local/bin"	# user executables
export PATH="$PATH:$HOME/.cargo/bin"			# cargo packages
export PATH="$PATH:$HOME/.local/share/npm/bin"		# npm global packages

# Shell integrations
source <(fzf --zsh)
eval "$(zoxide init --cmd cd zsh)"

if [[ "$TERM" == "xterm-ghostty" ]]
then
	export HAS_NERD_FONT=true
fi

# Enable vim mode
bindkey -v

# Better pacdiff
alias pacdiff='DIFFPROG="nvim -d" pacdiff -b -3 -s'

# Open file in [t]ext [e]ditor
alias te='$EDITOR'
# Open all files with changes in a git repository
alias diffed='$EDITOR $(git diff --name-only --relative)'

# Run nvim without plugins (in case of wierd behaviour)
alias vim="nvim --noplugin"
