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
vim.o.virtualedit = "block,onemore"
vim.o.wrap = true

vim.cmd.colorscheme("default")

vim.keymap.set("n", "<leader>q", "<cmd>bdelete<cr>")
vim.keymap.set("n", "<leader>f", function()
	(vim.bo.filetype == "netrw" and vim.cmd.Rexplore or vim.cmd.Explore)()
end)

vim.keymap.set("n", "gqc", "<cmd>cclose<cr>")
vim.keymap.set("n", "gqd", function()
	vim.diagnostic.setqflist({ severity = { min = vim.diagnostic.severity.INFO } })
end)
vim.keymap.set("n", "glc", "<cmd>lclose<cr>")
vim.keymap.set("n", "gld", function()
	vim.diagnostic.setloclist({ severity = { min = vim.diagnostic.severity.INFO } })
end)

--stylua: ignore
vim.keymap.set({ "i", "s" }, "<C-h>", function() vim.snippet.jump(-1) end)
--stylua: ignore
vim.keymap.set({ "i", "s" }, "<C-l>", function() vim.snippet.jump(1) end)

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("hl-on-yank", { clear = true }),
	--stylua: ignore
	callback = function() vim.hl.on_yank() end,
})
