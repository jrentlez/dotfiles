vim.pack.add({ "https://github.com/echasnovski/mini.nvim" })

-- Enable project local configuration
vim.o.exrc = true

-- Use space as the one and only true leader key
vim.g.mapleader = " "

-- Use the terminal to copy/paste
vim.g.clipboard = "osc52"

-- Options ---------------------------------------------------------------------

vim.o.breakindent = true
vim.o.clipboard = "unnamedplus"
vim.o.cursorline = true
vim.o.ignorecase = true
vim.o.inccommand = "split"
vim.o.incsearch = true
vim.o.infercase = true
vim.o.linebreak = true
vim.o.list = true
vim.o.listchars = "tab:> ,extends:…,precedes:…,nbsp:␣"
vim.o.mouse = "a"
vim.o.number = true
vim.o.pumheight = 10
vim.o.relativenumber = true
vim.o.scrolloff = 10
vim.o.signcolumn = "yes"
vim.o.smartcase = true
vim.o.smartindent = true
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.timeoutlen = 300
vim.o.undofile = true
vim.o.updatetime = 250
vim.o.virtualedit = "block"
vim.o.wrap = true

-- Keymaps ---------------------------------------------------------------------

vim.keymap.set({ "n", "x" }, "j", [[v:count == 0 ? 'gj' : 'j']], { expr = true })
vim.keymap.set({ "n", "x" }, "k", [[v:count == 0 ? 'gk' : 'k']], { expr = true })

local function nmap(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { desc = desc })
end

nmap("<Esc>", "<cmd>nohlsearch<cr>", "Clear highlights on search when pressing <Esc> in normal mode (:h hlsearch)")

nmap("<leader>q", "<cmd>bdelete<cr>", "Delete buffer")

---@type vim.diagnostic.Opts?
local config_backup = nil
nmap("<leader>e", function()
	if config_backup then
		vim.diagnostic.config(config_backup)
		config_backup = nil
	else
		config_backup = assert(vim.diagnostic.config())
		vim.diagnostic.config({
			virtual_lines = { current_line = true },
			virtual_text = false,
		})
	end
end, "Toggle line diagnostics with virtual lines")

nmap("gb", "<cmd>bnext<cr>", "Go to next buffer")
nmap("gB", "<cmd>bprevious<cr>", "Go to pevious buffer")

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Misc ------------------------------------------------------------------------

vim.cmd.colorscheme("default")

vim.diagnostic.config({
	virtual_text = { source = "if_many" },
})

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

vim.api.nvim_create_user_command("PackUpdate", function()
	vim.pack.update()
end, { desc = "Update plugins" })

vim.api.nvim_create_user_command("PackClean", function()
	local inactive_names = vim.iter(vim.pack.get())
		:map(function(package)
			return not package.active and package.spec.name or nil
		end)
		:totable()

	local msg = "Delete these inactive packages?\n\n"
	vim.iter(inactive_names):each(function(package_name)
		msg = msg .. package_name .. "\n"
	end)

	local confirmed = vim.fn.confirm(msg) == 1
	if confirmed then
		vim.pack.del(inactive_names)
	end
end, { desc = "Delete inactive plugins" })
