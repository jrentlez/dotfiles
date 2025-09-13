vim.g.mapleader = " "
vim.g.clipboard = "osc52"

vim.o.breakindent = true
vim.o.completeopt = "menuone,fuzzy,noinsert,popup"
vim.o.cursorline = true
vim.o.exrc = true
vim.o.ignorecase = true
vim.o.inccommand = "split"
vim.o.infercase = true
vim.o.linebreak = true
vim.o.list = true
vim.o.number = true
vim.o.pumheight = 10
vim.o.relativenumber = true
vim.o.scrolloff = 5
vim.o.signcolumn = "yes"
vim.o.smartcase = true
vim.o.splitright = true
vim.o.undofile = true
vim.o.virtualedit = "block"
vim.o.wrap = true

vim.cmd.colorscheme("terminal")

vim.keymap.set("n", "<leader>q", "<cmd>bdelete<cr>")
vim.keymap.set("n", "<leader>f", "<cmd>Explore<cr>")

vim.keymap.set("n", "gqc", "<cmd>cclose<cr>")
vim.keymap.set("n", "gqd", vim.diagnostic.setqflist)
vim.keymap.set("n", "glc", "<cmd>lclose<cr>")
vim.keymap.set("n", "gld", vim.diagnostic.setloclist)

vim.keymap.del({ "i", "s" }, "<S-Tab>")
vim.keymap.del({ "i", "s" }, "<Tab>")
-- stylua: ignore start
vim.keymap.set({ "i", "s" }, "<C-h>", function() vim.snippet.jump(-1) end)
vim.keymap.set({ "i", "s" }, "<C-l>", function() vim.snippet.jump(1) end)

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("hl-on-yank", { clear = true }),
	callback = function() vim.hl.on_yank() end,
})
-- stylua: ignore end

--- See `:help package-nohlsearch`
vim.cmd.packadd({ "nohlsearch", bang = true })
