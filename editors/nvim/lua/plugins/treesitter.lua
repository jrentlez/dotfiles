local add, now = MiniDeps.add, MiniDeps.now

-- Finish treesitter setup for a buffer
---@param buf integer buffer
---@param lang string treesitter language
local function finish_setup(buf, lang)
	vim.treesitter.start(buf, lang)
	vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end

-- Setup treesitter for a buffer
---@param buf integer buffer
---@param ft string? explicitly set filetype
local function setup_treesitter(buf, ft)
	ft = ft or vim.api.nvim_get_option_value("ft", { buf = buf })
	local lang = vim.treesitter.language.get_lang(ft) or ft
	local cfg = require("nvim-treesitter.config")

	local available = vim.list_contains(cfg.get_available(), lang)
	if not available then
		return
	end

	local installed = vim.list_contains(cfg.installed_parsers(), lang)
	if installed then
		finish_setup(buf, lang)
		return
	end

	require("nvim-treesitter.install").install({ lang }, nil, function()
		finish_setup(buf, lang)
	end)
end

now(function()
	add({
		source = "nvim-treesitter/nvim-treesitter",
		checkout = "main",
		monitor = "main",
		hooks = {
			post_checkout = function()
				vim.cmd("TSUpdate")
			end,
		},
	})

	require("nvim-treesitter").setup({
		ensure_install = { "stable" },
	})

	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("NvimTreesitter-custom-setup", { clear = true }),
		---@param args {match: string, buf: integer} `match` is the filetype and `buf` the buffer for the autocmd
		callback = function(args)
			setup_treesitter(args.buf, args.match)
		end,
	})
end)
