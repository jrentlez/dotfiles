---@module "mini.deps"

local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

--- Ensure a buffer has its appropriate parser installed
---@param bufnr integer The buffer to check
---@param on_installed fun() Called once the parser is installed. If there is no appropriate parser for the buffer, `on_installed` is never called.
local function ensure_installed(bufnr, on_installed)
	local language = assert(
		vim.treesitter.language.get_lang(vim.bo[bufnr].filetype),
		"Only returns nil if filetype is '' which it never is"
	)
	if vim.list_contains(require("nvim-treesitter").get_installed(), language) then
		on_installed()
	elseif vim.list_contains(require("nvim-treesitter").get_available(), language) then
		require("nvim-treesitter").install(language, { summary = true }):await(function(err)
			if err then
				error(err, vim.log.levels.ERROR)
			else
				on_installed()
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
				require("nvim-treesitter").update({ summary = true })
			end,
		},
	})

	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("nvim-treesitter-buffer-setup", { clear = true }),
		callback = function(args)
			ensure_installed(args.buf, function()
				vim.treesitter.start(args.buf)
				vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end)
		end,
		desc = "Ensure the appropriate parser is installed and start it",
	})
end)

later(function()
	local installed = require("nvim-treesitter").get_installed()
	local required_parsers = vim.iter({
		"c",
		"lua",
		"markdown",
		"markdown_inline",
		"query",
		"vim",
		"vimdoc",
		"comment",
	})
		:filter(function(parser)
			return not vim.list_contains(installed, parser)
		end)
		:totable()
	require("nvim-treesitter").install(required_parsers, { summary = true })
end)
