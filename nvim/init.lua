-- {{{ Global Variables
vim.g.mapleader = " "
vim.g.clipboard = "osc52" -- }}}
-- {{{ Options
vim.o.breakindent = true
vim.o.completeopt = "menuone,fuzzy,noinsert,popup"
vim.o.cursorline = true
vim.o.exrc = true
vim.o.ignorecase = true
vim.o.inccommand = "split"
vim.o.incsearch = true
vim.o.infercase = true
vim.o.linebreak = true
vim.o.list = true
vim.o.mouse = "a"
vim.o.number = true
vim.o.pumheight = 10
vim.o.relativenumber = true
vim.o.scrolloff = 5
vim.o.signcolumn = "yes"
vim.o.smartcase = true
vim.o.smartindent = true
vim.o.splitright = true
vim.o.undofile = true
vim.o.virtualedit = "block"
vim.o.wrap = true -- }}}
-- {{{ Colorscheme
vim.cmd.colorscheme("terminal") -- }}}
-- {{{ Keymaps
vim.keymap.set({ "n", "x" }, "j", [[v:count == 0 ? 'gj' : 'j']], { expr = true })
vim.keymap.set({ "n", "x" }, "k", [[v:count == 0 ? 'gk' : 'k']], { expr = true })

---@param lhs string
---@param rhs string | function
---@param desc string
local function nmap(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { desc = desc })
end

nmap("<leader>q", "<cmd>bdelete<cr>", "Delete buffer")

nmap("gqo", "<cmd>copen<cr>", ":copen")
nmap("gqc", "<cmd>cclose<cr>", ":cclose")
nmap("gqd", vim.diagnostic.setqflist, "vim.diagnostic.setqflist()")

nmap("glo", "<cmd>lopen<cr>", ":lopen")
nmap("glp", "<cmd>lprevious<cr>", ":lprevious")
nmap("gld", vim.diagnostic.setloclist, "vim.diagnostic.setloclist()")

vim.keymap.del({ "i", "s" }, "<S-Tab>")
vim.keymap.del({ "i", "s" }, "<Tab>")
vim.keymap.set({ "i", "s" }, "<C-h>", function()
	vim.snippet.jump(-1)
end, { desc = "Jump to previous snippet insertion" })
vim.keymap.set({ "i", "s" }, "<C-l>", function()
	vim.snippet.jump(1)
end, { desc = "Jump to next snippet insertion" }) -- }}}
-- {{{ Autocommands
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("hl_on_yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
	desc = "Highlight yanked text",
}) -- }}}
-- {{{ User commands
vim.api.nvim_create_user_command("PackUpdate", function()
	vim.pack.update()
end, { desc = "Update plugins" })

vim.api.nvim_create_user_command("PackClean", function()
	local inactive_names = vim.tbl_map(function(plugin)
		return not plugin.active and plugin.spec.name or nil
	end, vim.pack.get()) ---@type string[]

	if vim.tbl_isempty(inactive_names) then
		vim.print("Nothing to clean")
		return
	end

	local message = "Delete these inactive plugins?\n\n"
	for _, inactive_name in ipairs(inactive_names) do
		message = message .. inactive_name .. "\n"
	end

	if vim.fn.confirm(message) == 1 then
		vim.pack.del(inactive_names)
	end
end, { desc = "Delete inactive plugins" }) -- }}}
