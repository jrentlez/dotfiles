# version = "0.103"

$env.config.show_banner = false
$env.config.datetime_format.normal = '%a, %d %b %Y %H:%M:%S %z'
$env.config.datetime_format.table = '%d/%m/%y %I:%M:%S%p'
$env.config.edit_mode = "vi"
$env.config.cursor_shape.vi_insert = "line"
$env.config.cursor_shape.vi_normal = "block"
$env.config.use_kitty_protocol = true
$env.config.highlight_resolved_externals = true

$env.config.color_config.bool = "default"
$env.config.color_config.int = "default"
$env.config.color_config.filesize = "default"
$env.config.color_config.duration = "default"
$env.config.color_config.date = "default"
$env.config.color_config.range = "default"
$env.config.color_config.float = "default"
$env.config.color_config.nothing = "default"
$env.config.color_config.binary = "default"
$env.config.color_config.cell-path = "default"
$env.config.color_config.string = "default"

$env.config.color_config.separator = "default_dimmed"
$env.config.color_config.record = "default_dimmed"
$env.config.color_config.list = "default_dimmed"
$env.config.color_config.block = "default_dimmed"
$env.config.color_config.block = "default_dimmed"
$env.config.color_config.hints = "light_gray_dimmed"

alias yeet = pacman -Rns
alias pacdiff = with-env {DIFFPROG: "nvim -d"} {^pacdiff -b -3 -s}

alias te = nvim		# FIXME: This should execute $env.EDITOR, but nushell then doesn't do auto completion
alias diffed = te ...(git diff --name-only --relative | lines)

alias nu-ls = ls		# Backup nushell's builtin `ls`

# Wrap nushell's `ls` to print a grid with icons
def ls [
	...pattern # The glob pattern to use
	--all (-a) # Show hidden files
]: nothing -> string {
	if $all {if ($pattern | is-empty) {nu-ls -a} else {nu-ls ...$pattern -a}} else {if ($pattern | is-empty) {nu-ls} else {nu-ls ...$pattern}} | sort-by type name -i | grid --color --icons
}

# Update the prompt command
def update-prompt []: nothing -> nothing {
	cd ($env.HOME | path join .config nushell prompt)
	^cargo install --path .
}

alias lt = eza --icons --tree

source ~/.cache/carapace/init.nu
source ~/.cache/zoxide/init.nu
