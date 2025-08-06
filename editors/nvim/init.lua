-- Global Variables ------------------------------------------------------------
vim.g.mapleader = " "
vim.g.clipboard = "osc52"

-- Options ---------------------------------------------------------------------

vim.o.autocomplete = true
vim.o.breakindent = true
vim.o.clipboard = "unnamedplus"
vim.o.complete = "o"
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
vim.o.scrolloff = 10
vim.o.signcolumn = "yes"
vim.o.smartcase = true
vim.o.smartindent = true
vim.o.splitright = true
vim.o.timeoutlen = 300
vim.o.undofile = true
vim.o.updatetime = 250
vim.o.virtualedit = "block"
vim.o.wrap = true

-- Colorscheme -----------------------------------------------------------------

vim.cmd.colorscheme("terminal")

-- Keymaps ---------------------------------------------------------------------

vim.keymap.set({ "n", "x" }, "j", [[v:count == 0 ? 'gj' : 'j']], { expr = true })
vim.keymap.set({ "n", "x" }, "k", [[v:count == 0 ? 'gk' : 'k']], { expr = true })

---@param lhs string
---@param rhs string | function
---@param desc string
local function nmap(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { desc = desc })
end

nmap("<Esc>", "<cmd>nohlsearch<cr>", "Clear highlights on search when pressing <Esc> in normal mode (:h hlsearch)")

nmap("<leader>q", "<cmd>bdelete<cr>", "Delete buffer")

nmap("gb", "<cmd>bnext<cr>", "Go to next buffer")
nmap("gB", "<cmd>bprevious<cr>", "Go to pevious buffer")

nmap("gqo", "<cmd>copen<cr>", ":copen")
nmap("gqc", "<cmd>cclose<cr>", ":cclose")
nmap("gqn", "<cmd>cnext<cr>", ":cnext")
nmap("gqp", "<cmd>cprevious<cr>", ":cprevious")
nmap("gqd", vim.diagnostic.setqflist, "vim.diagnostic.setqflist()")

nmap("glo", "<cmd>lopen<cr>", ":lopen")
nmap("glc", "<cmd>lclose<cr>", ":lclose")
nmap("gln", "<cmd>lnext<cr>", ":lnext")
nmap("glp", "<cmd>lprevious<cr>", ":lprevious")
nmap("gld", vim.diagnostic.setloclist, "vim.diagnostic.setloclist()")

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

vim.keymap.del({ "i", "s" }, "<S-Tab>")
vim.keymap.del({ "i", "s" }, "<Tab>")
vim.keymap.set({ "i", "s" }, "<C-h>", function()
	vim.snippet.jump(-1)
end)
vim.keymap.set({ "i", "s" }, "<C-l>", function()
	vim.snippet.jump(1)
end)

-- Autocommands ----------------------------------------------------------------

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("hl_on_yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
	desc = "Highlight yanked text",
})

vim.api.nvim_create_autocmd("BufRead", {
	group = vim.api.nvim_create_augroup("ro_nomodifiable", { clear = true }),
	callback = function(args)
		if vim.bo[args.buf].readonly then
			vim.bo[args.buf].modifiable = false
		end
	end,
	desc = "Make readonly buffers nomodifiable",
})

-- User commands ---------------------------------------------------------------

vim.api.nvim_create_user_command("PackUpdate", function()
	vim.pack.update()
end, { desc = "Update plugins" })

vim.api.nvim_create_user_command("PackClean", function()
	local inactive_names = vim.iter(vim.pack.get())
		:map(
			---@param plugin vim.pack.PlugData
			function(plugin)
				return not plugin.active and plugin.spec.name or nil
			end
		)
		:totable() --[[@as string[] ]]

	if vim.tbl_isempty(inactive_names) then
		vim.print("Nothing to clean")
		return
	end

	local message = vim.iter(inactive_names):fold(
		"Delete these inactive plugins?\n\n",
		---@param plugin_name string
		function(msg, plugin_name)
			return msg .. plugin_name .. "\n"
		end
	) --[[@as string]]

	local confirmed = vim.fn.confirm(message) == 1
	if confirmed then
		vim.pack.del(inactive_names)
	end
end, { desc = "Delete inactive plugins" })
