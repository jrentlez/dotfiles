# version = "0.99.1"

$env.config = {
    show_banner: false

    table: {
        index_mode: auto
    }

    error_style: "fancy" # "fancy" or "plain" for screen reader-friendly error messages

    datetime_format: {
        normal: '%a, %d %b %Y %H:%M:%S %z'    # shows up in displays of variables or other datetime's outside of tables
        table: '%d/%m/%y %I:%M:%S%p'          # generally shows up in tabular outputs such as ls. commenting this out will change it to the default human readable datetime format
    }

    completions: {
        partial: false    # set this to false to prevent partial filling of the prompt
        algorithm: "fuzzy"    # prefix or fuzzy
    }

    cursor_shape: {
        emacs: line # block, underscore, line, blink_block, blink_underscore, blink_line, inherit to skip setting cursor shape (line is the default)
        vi_insert: line # block, underscore, line, blink_block, blink_underscore, blink_line, inherit
        vi_normal: block # block, underscore, line, blink_block, blink_underscore, blink_line, inherit
    }

    footer_mode: always # always, never, number_of_rows, auto
    float_precision: 2
    edit_mode: vi
    shell_integration: {
        # osc2 abbreviates the path if in the home_dir, sets the tab/window title, shows the running command in the tab/window title
        osc2: true
        # osc7 is a way to communicate the path to the terminal, this is helpful for spawning new tabs in the same directory
        osc7: true
        # osc8 is also implemented as the deprecated setting ls.show_clickable_links, it shows clickable links in ls output if your terminal supports it. show_clickable_links is deprecated in favor of osc8
        osc8: true
        # osc9_9 is from ConEmu and is starting to get wider support. It's similar to osc7 in that it communicates the path to the terminal
        osc9_9: true
        # osc133 is several escapes invented by Final Term which include the supported ones below.
        # 133;A - Mark prompt start
        # 133;B - Mark prompt end
        # 133;C - Mark pre-execution
        # 133;D;exit - Mark execution finished with exit code
        # This is used to enable terminals to know where the prompt is, the command is, where the command finishes, and where the output of the command is
        osc133: true
        # osc633 is closely related to osc133 but only exists in visual studio code (vscode) and supports their shell integration features
        # 633;A - Mark prompt start
        # 633;B - Mark prompt end
        # 633;C - Mark pre-execution
        # 633;D;exit - Mark execution finished with exit code
        # 633;E - Explicitly set the command line with an optional nonce
        # 633;P;Cwd=<path> - Mark the current working directory and communicate it to the terminal
        # and also helps with the run recent menu in vscode
        osc633: true
        # reset_application_mode is escape \x1b[?1l and was added to help ssh work better
        reset_application_mode: true
    }
    render_right_prompt_on_last_line: true # true or false to enable or disable right prompt to be rendered on last line of the prompt.
    use_kitty_protocol: true # enables keyboard enhancement protocol implemented by kitty console, only if your terminal support this.
    highlight_resolved_externals: true # true enables highlighting of external commands in the repl resolved by which.
    recursion_limit: 50
}

alias yeet = pacman -Rns
alias pacdiff = with-env {DIFFPROG: "nvim -d"} {pacdiff -b -3 -s}

alias ed = nvim		# FIXME: This should execute $env.EDITOR, but nushell then doesn't do auto completion
alias diffed = ed ...(git diff --name-only --relative | lines)

alias nu-ls = ls		# Backup nushell's builtin `ls`

# Wrap nushell's `ls` to print a grid with icons
def ls [
	...pattern # The glob pattern to use
	--all (-a) # Show hidden files
]: nothing -> string {
	if $all {if ($pattern | is-empty) {nu-ls -a} else {nu-ls ...$pattern -a}} else {if ($pattern | is-empty) {nu-ls} else {nu-ls ...$pattern}} | sort-by type name -i | grid --color --icons
}

alias lt = eza --icons --tree

use ~/.cache/starship/init.nu
source ~/.cache/carapace/init.nu
source ~/.cache/zoxide/init.nu
