-- {{{ Auto recompile on nvim-treesitter change
vim.api.nvim_create_autocmd("PackChanged", {
	group = vim.api.nvim_create_augroup("nvim-treesitter-update-parsers", { clear = true }),
	callback = function(args)
		local kind = args.data.kind --[[@as "install" | "update" | "delete"]]
		local spec = args.data.spec --[[@as vim.pack.SpecResolved]]
		if spec.name == "nvim-treesitter" and kind ~= "delete" then
			require("nvim-treesitter").update({ summary = true })
		end
	end,
	desc = "Update treesitter parsers",
}) -- }}}
vim.pack.add({ {
	src = "https://github.com/nvim-treesitter/nvim-treesitter.git",
	version = "main",
} })

-- {{{ Auto install missing parsers
---@param bufnr integer
---@param on_installed fun()
local function ensure_installed(bufnr, on_installed)
	local language = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
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

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("nvim-treesitter-buffer-setup", { clear = true }),
	callback = function(args)
		ensure_installed(args.buf, function()
			vim.treesitter.start(args.buf)
			vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end)
	end,
	desc = "Ensure the appropriate parser is installed and start it",
}) -- }}}

vim.schedule(function()
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
		"diff",
	})
		:filter(function(parser)
			return not vim.list_contains(installed, parser)
		end)
		:totable()
	require("nvim-treesitter").install(required_parsers, { summary = true })
end)
