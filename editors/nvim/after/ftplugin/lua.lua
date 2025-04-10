---@module "mini.deps"

vim.b.lspfmt = "stylua3p_ls"

-- Add neovim lua modules to path
MiniDeps.add("folke/lazydev.nvim")
require("lazydev").setup()
