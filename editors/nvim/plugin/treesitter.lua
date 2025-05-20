---@module "mini.deps"

local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

--- Finish treesitter setup for a buffer
---@param buf integer buffer
---@param lang string treesitter language
local function finish_setup(buf, lang)
	vim.treesitter.start(buf, lang)
	vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end

--- Setup treesitter for a buffer
---@param buf integer buffer
---@param ft string? explicitly set filetype
local function setup_treesitter(buf, ft)
	ft = ft or vim.bo[buf].filetype

	local lang = vim.treesitter.language.get_lang(ft) or ft
	if vim.list_contains(require("nvim-treesitter.config").installed_parsers(), lang) then
		finish_setup(buf, lang)
	elseif vim.list_contains(require("nvim-treesitter.config").get_available(), lang) then
		require("nvim-treesitter.install").install(lang):await(function(err)
			if err then
				error(err, vim.log.levels.ERROR)
			else
				finish_setup(buf, lang)
			end
		end)
	end
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

	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("NvimTreesitter-custom-setup", { clear = true }),
		callback = function(args)
			setup_treesitter(args.buf, args.match)
		end,
	})
end)

later(function()
	local installed = require("nvim-treesitter.config").installed_parsers()
	local required_parsers = vim.iter({
		"c",
		"lua",
		"markdown",
		"markdown_inline",
		"query",
		"vim",
		"vimdoc",
	})
		:filter(function(parser)
			return not vim.list_contains(installed, parser)
		end)
		:totable()
	require("nvim-treesitter.install").install(required_parsers)
end)
