---@module "mini.deps"

local add, now = MiniDeps.add, MiniDeps.now

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
	if lang == "jayvee" or vim.list_contains(require("nvim-treesitter.config").installed_parsers(), lang) then
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
		callback = function(args)
			setup_treesitter(args.buf, args.match)
		end,
	})
end)
