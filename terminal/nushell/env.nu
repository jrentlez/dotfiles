# version = "0.104"

$env.PROMPT_COMMAND = {|| ^prompt (job list | length) $env.LAST_EXIT_CODE }
$env.PROMPT_COMMAND_RIGHT = ""

use std/config env-conversions
$env.ENV_CONVERSIONS = env-conversions

# Directories to search for scripts when calling source or use
$env.NU_LIB_DIRS = $env.NU_LIB_DIRS | append [
    ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
    ($nu.data-dir | path join 'completions') # default home for nushell completions
    $nu.default-config-dir
]

$env.LS_COLORS = (dircolors | lines | get 0 | parse "LS_COLORS='{colors}';" | get colors | get 0)

$env.EDITOR = 'nvim'
#HINT: use `bat` to syntax highlight manpages
$env.MANPAGER = r#'sh -c 'sed -u -e "s/\\x1B\[[0-9;]*m//g; s/.\\x08//g" | bat -p -lman''#

let additional_bin_paths = [".bin", ".local/bin", ".cargo/bin", ".go/bin", ".local/share/npm/bin"];
$env.PATH = $env.PATH | prepend ($additional_bin_paths | each {|p| $env.HOME | path join $p}) | uniq
$env.npm_config_prefix = $env.HOME | path join ".local/share/npm"

$env.VIRTUAL_ENV_DISABLE_PROMPT = true

$env.HAS_NERD_FONT = true

$env.CARAPACE_BRIDGES = 'zsh,bash'
mkdir ~/.cache/carapace
carapace _carapace nushell | save --force ~/.cache/carapace/init.nu

mkdir ~/.cache/zoxide
zoxide init --cmd cd nushell | save -f ~/.cache/zoxide/init.nu
