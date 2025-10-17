# Environment Variables
export PATH="$HOME/.local/bin/:$HOME/.cargo/bin:$HOME/.local/share/npm/bin:$PATH"
[[ ! -v EDITOR ]] && export EDITOR='nvim'
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
function __git_path() {
	git rev-parse --git-path "$1"
}
function __git_eread() {
	local pth
	pth="$(__git_path "$1")"
	test -r "$pth" && IFS=$'\r\n' read -r "$2" <"$pth"
}
function __git_prompt() {
	local action step total todo
	git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return
	if [[ -d "$(__git_path rebase-merge)" ]]; then
		__git_eread "rebase-merge/msgnum" step
		__git_eread "rebase-merge/end" total
		action="rebase"
	elif [[ -d "$(__git_path rebase-apply)" ]]; then
		__git_eread "rebase-apply/next" step
		__git_eread "rebase-apply/last" total
		if [ -f "$(__git_path rebase-apply/rebasing)" ]; then
			action="rebase"
		elif [ -f "$(__git_path rebase-apply/applying)" ]; then
			action="mailbox"
		else
			action="mailbox/rebase"
		fi
	elif [[ -f "$(__git_path MERGE_HEAD)" ]]; then
		action="merging"
	elif [[ -f "$(__git_path CHERRY_PICK_HEAD)" ]]; then
		action="cherry-picking"
	elif __git_eread "sequencer/todo" todo; then
		case "$todo" in
		p[\ \	] | pick[\ \	]*)
			action="cherry-picking"
			;;
		revert[\ \	]*)
			action="reverting"
			;;
		esac
	elif [[ -f "$(__git_path BISECT_LOG)" ]]; then
		action="bisecting"
	fi

	local git_status
	if [[ -n "$step" && -n "$total" ]]; then
		git_status="$step/$total "
	fi

	local head upstream ahead behind stash
	local wt_modified wt_type_change wt_added wt_deleted wt_renamed
	local i_modified i_type_change i_added i_deleted i_renamed
	local conflict untracked

	local OIFS=$IFS
	IFS=$'\n'
	for line in $(git status --porcelain=2 --branch --show-stash); do
		case "$line" in
		'# branch.oid '*) ;;
		'# branch.head '*) head="${line##'# branch.head '}" ;;
		'# branch.upstream '*) upstream="${line##'# branch.upstream '}" ;;
		'# branch.ab '*)
			case "${line##'# branch.ab '}" in
			'+0 -0') ;;
			'+0 -'*) behind='B' ;;
			'+'*' -0') ahead='A' ;;
			'+'*' -'*) ahead='A'; behind='B' ;;
			esac
			;;
		'# stash '*) stash='S' ;;
		'1 '* | 'u '*)
			[[ "${line:0:1}" == u ]] && conflict='C'
			case "${line:2:1}" in
			.) ;;
			M) i_modified='M' ;;
			T) i_type_change='T' ;;
			A) i_added='A' ;;
			D) i_deleted='D' ;;
			R | C) i_renamed='R' ;;
			U) conflict='C' ;;
			esac
			case "${line:3:1}" in
			.) ;;
			M) wt_modified='m' ;;
			T) wt_type_change='t' ;;
			A) wt_added='a' ;;
			D) wt_deleted='d' ;;
			R | C) wt_renamed='r' ;;
			U) conflict='C' ;;
			esac
			;;
		'? '*) untracked='?' ;;
		'! '*) ;;
		*) echo "Unexpected git porcelain: $line" 1>&2 ;;
		esac
	done
	IFS=$OIFS
	git_status+="$untracked$wt_added$wt_renamed$wt_type_change$wt_modified$wt_deleted$i_added$i_renamed$i_type_change$i_modified$i_deleted$conflict$stash"

	if [[ -n $upstream ]]; then
		local upstream_name
		upstream_name="$(basename "$upstream")"
		if [[ $upstream_name == "$head" ]]; then
			head="$upstream"
		else
			head="$head:$upstream"
		fi
	fi

	echo " %{\e[39;2m%}${action:-$head}%{\e[39;0m%}%F{yellow}$git_status%f$ahead$behind"
}
newline=$'\n'
PS1='$(__format_wd)$(__git_prompt)${newline}%(0?.%(1j.%F{blue}%#%f.%#).%(1j.%F{magenta}%#%f.%F{red}%#%f)) '

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
	dir="$(fd --type d --maxdepth 5 --follow ${fd_excludes[@]} . ${dirs_[@]} |
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
