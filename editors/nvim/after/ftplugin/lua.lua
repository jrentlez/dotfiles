vim.b.lspfmt = "stylua3p_ls"

-- Add neovim lua modules to path
vim.pack.add({ "https://github.com/folke/lazydev.nvim.git" })
require("lazydev").setup()
