# Environment Variables
export PATH="$HOME/.local/share/bob/nvim-bin:$HOME/.local/bin/:$HOME/.bin:$HOME/.cargo/bin:$HOME/.local/share/npm/bin:$PATH"
[[ ! -v EDITOR ]] && export EDITOR='nvim'
export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
export npm_config_prefix="$HOME/.local/share/npm"
export NVIM_SHELL="zsh"
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/ripgrep/ripgreprc"

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

# Prompt
precmd() { precmd() { print "" } }                  # Print blank line before each prompt but the first
alias clear="precmd() {precmd() {echo }} && clear"  # Prevent clear from inserting a prompt
zmodload zsh/parameter                              # Needed to access jobstates variable
setopt promptsubst
PS1='$(prompt jobs="${#jobstates}" laststatus="$?" shell=zsh)'

# Aliases
alias ls='ls --color'
alias tree='tree -C'
alias te="$EDITOR"
alias vim="nvim --noplugin"
alias diffed='$EDITOR $(git diff --name-only --relative)'
alias pacdiff='DIFFPROG="nvim -d" pacdiff -b -3 -s'

# Completions
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' insert-unambiguous true
zstyle ':completion:*' original false
zstyle ':completion:*' verbose true
autoload -Uz compinit bashcompinit
compinit
bashcompinit

# Skim
export SKIM_DEFAULT_OPTIONS="--ansi --color=bw"
function skim-homedir-widget() {
	local fd_excludes
	fd_excludes=("--exclude=.cache" "--exclude=.git" "--exclude=node_modules" "--exclude=target")
	local dirs_
	dirs_=("$HOME" "$HOME/.local/state/nvim" "$HOME/.local/share/nvim" "$HOME/.config")
	local dir
	dir="$(fd --type d --maxdepth 8 --follow ${fd_excludes[@]} . ${dirs_[@]} |
		sk --no-multi)"
	if [[ -z "$dir" ]]; then
		zle redisplay
		return 0
	fi
	if [[ -z "$BUFFER" ]]; then
		BUFFER="cd ${(q)dir}"
		zle accept-line
	else
		print -sr "cd ${(q)dir}"
		cd "$dir"
	fi
	local ret
	ret=$?
	zle skim-redraw-prompt
	tput cnorm
	return $ret
}
zle -N skim-homedir-widget
bindkey '^F' skim-homedir-widget

