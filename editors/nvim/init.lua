-- Install mini.nvim
local path_package = vim.fs.joinpath(vim.fn.stdpath("data"), "/site")
local mini_path = vim.fs.joinpath(path_package, "/pack/deps/start/mini.nvim")
if not vim.uv.fs_stat(mini_path) then
	vim.cmd('echo "Installing `mini.nvim`" | redraw')
	local clone_cmd = {
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/echasnovski/mini.nvim",
		mini_path,
	}
	local out = vim.fn.system(clone_cmd)
	if vim.v.shell_error ~= 0 then
		error("Error cloning mini.nvim\n" .. out)
	end
	vim.cmd("packadd mini.nvim | helptags ALL")
end

-- Plugin manager
require("mini.deps").setup({ path = { package = path_package } })

-- Enable project local configuration
vim.o.exrc = true

-- Use space as the one and only true leader key
vim.g.mapleader = " "

-- Options ---------------------------------------------------------------------

vim.o.breakindent = true
vim.o.clipboard = "unnamedplus"
vim.o.conceallevel = 2
vim.o.cursorline = true
vim.o.formatoptions = "qjl1"
vim.o.ignorecase = true
vim.o.inccommand = "split"
vim.o.incsearch = true
vim.o.infercase = true
vim.o.linebreak = true
vim.o.list = true
vim.o.listchars = "tab:> ,extends:…,precedes:…,nbsp:␣"
vim.o.mouse = "a"
vim.o.number = true
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
vim.opt.shortmess:append("cC")

-- Keymaps ---------------------------------------------------------------------

vim.keymap.set({ "n", "x" }, "j", [[v:count == 0 ? 'gj' : 'j']], { expr = true })
vim.keymap.set({ "n", "x" }, "k", [[v:count == 0 ? 'gk' : 'k']], { expr = true })

local function nmap(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { desc = desc })
end

nmap("<Esc>", "<cmd>nohlsearch<cr>", "Clear highlights on search when pressing <Esc> in normal mode (:h hlsearch)")

nmap("<leader>q", vim.diagnostic.setqflist, "Open diagnostic quickfixlist")

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
