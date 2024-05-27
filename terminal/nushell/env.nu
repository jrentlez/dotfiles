# version = "0.99.1"

$env.PROMPT_INDICATOR = {|| "> " }
$env.PROMPT_INDICATOR_VI_INSERT = {|| ": " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| "> " }
$env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }

$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
    "Path": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
}

# Directories to search for scripts when calling source or use
$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
    ($nu.data-dir | path join 'completions') # default home for nushell completions
]

# Directories to search for plugin binaries when calling register
$env.NU_PLUGIN_DIRS = [
    $nu.default-config-dir
]


$env.EDITOR = 'nvim'

let additional_bin_paths = [".bin", ".local/bin", ".cargo/bin", ".go/bin", ".local/share/npm/bin"];
$env.PATH = $env.PATH | split row (char esep) | append ($additional_bin_paths | each {|p| $env.HOME | path join $p}) | uniq
$env.npm_config_prefix = $env.HOME | path join ".local/share/npm"

mkdir ~/.cache/carapace
carapace _carapace nushell | save --force ~/.cache/carapace/init.nu

mkdir ~/.cache/zoxide
zoxide init --cmd cd nushell | save -f ~/.cache/zoxide/init.nu
