# Environment Variables
export PATH="$HOME/.local/bin/:$HOME/.bin:$HOME/.cargo/bin:$HOME/.local/share/npm/bin:$PATH"
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
source /usr/share/git/git-prompt.sh
precmd() { precmd() { print "" } } # Print blank line before each prompt but the first
alias clear="precmd() {precmd() {echo }} && clear" # Prevent clear from inserting a prompt
setopt promptsubst
function __format_wd() {
	local wd
	print -v wd -P %~
	if [[ $wd == '/' ]]; then
		echo "%B/%b"
		return
	fi

	local base="${wd##*/}" dir="${wd%/*}"

	if [[ $dir != "$base" ]]; then
		echo "$dir/%B$base%b"
	else
		echo "%B$base%b"
	fi
}
function __prompt_git() {
	local out
	out="$(GIT_PS1_SHOWDIRTYSTATE=true GIT_PS1_SHOWSTASHSTATE=true GIT_PS1_SHOWUNTRACKEDFILES=true GIT_PS1_SHOWUPSTREAM=auto GIT_PS1_SHOWCONFLICTSTATE=yes __git_ps1 %s)"
	if [[ -z $out ]]; then return; fi
	out="${out/=/}"
	out="${out# }"

	local head="${out%% *}"
	out="${out##"$head"}"
	out="${out##* }"
	local state="${head##*\|}"
	if [[ $state != "$head" ]]; then
		head="$state"
	fi

	local upstream
	upstream="$(git branch --format='%(upstream)' --list "$head")"
	upstream="${upstream##refs/remotes/}"
	if [[ -n $upstream ]]; then
		local upstream_name
		upstream_name="$(basename "$upstream")"
		if [[ $upstream_name == "$head" ]]; then
			head="$upstream"
		else
			head="$head:$upstream"
		fi
	fi

	echo "%{\e[39;2m%}$head%{\e[39;0m%}%F{yellow}$out%f"
}
newline=$'\n'
PS1='$(__format_wd) $(__prompt_git)${newline}%(0?.%(1j.%F{blue}%#%f.%#).%(1j.%F{magenta}%#%f.%F{red}%#%f)) '

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
source "/usr/share/skim/key-bindings.zsh"
function skim-homedir-widget() {
	local fd_excludes=("--exclude=.cache" "--exclude=.git" "--exclude=node_modules" "--exclude=target")
	local dirs_=("$HOME" "$HOME/.local/state/nvim" "$HOME/.local/share/nvim" "$HOME/.config")
	local dir
	dir="$(fd --type d --maxdepth 8 --follow ${fd_excludes[@]} . ${dirs_[@]} |
		sk --no-multi)"
	if [[ -z $dir ]]; then
		zle redisplay
		return 0
	fi
	if [[ -z $BUFFER ]]; then
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
