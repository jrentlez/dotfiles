---@module "mini.deps"

local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

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
	if lang == "jayvee" then
		finish_setup(buf, lang)
	end

	local available = vim.list_contains(require("nvim-treesitter.config").get_available(), lang)
	if not available then
		return
	end

	local installed = vim.list_contains(require("nvim-treesitter.config").installed_parsers(), lang)
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

	vim.api.nvim_create_autocmd("User", {
		pattern = "TSUpdate",
		callback = function()
			require("nvim-treesitter.parsers").jayvee = {
				install_info = {
					url = "https://github.com/jvalue/tree-sitter-jayvee",
					revision = "3106c29e629f100fe5e4d3345bb848481b5e0ea5",
				},
				tier = 3,
			}
		end,
	})

	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("NvimTreesitter-custom-setup", { clear = true }),
		---@param args {match: string, buf: integer} `match` is the filetype and `buf` the buffer for the autocmd
		callback = function(args)
			setup_treesitter(args.buf, args.match)
		end,
	})
end)
