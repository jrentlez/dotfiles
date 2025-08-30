vim.api.nvim_create_autocmd("PackChanged", {
	group = vim.api.nvim_create_augroup("nvim-treesitter-update-parsers", { clear = true }),
	callback = function(args)
		local kind = args.data.kind --[[@as "install" | "update" | "delete"]]
		local spec = args.data.spec --[[@as vim.pack.SpecResolved]]
		if spec.name == "nvim-treesitter" and kind ~= "delete" then
			require("nvim-treesitter").update({ summary = true })
		end
	end,
})
vim.pack.add({ {
	src = "https://github.com/nvim-treesitter/nvim-treesitter",
	version = "main",
} }, { load = true })

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("nvim-treesitter-buffer-setup", { clear = true }),
	callback = function(args)
		-- {{{ Ensure parser is installed and start it
		local language = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
		if vim.list_contains(require("nvim-treesitter").get_installed(), language) then
			vim.treesitter.start(args.buf)
			vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		elseif vim.list_contains(require("nvim-treesitter").get_available(), language) then
			require("nvim-treesitter").install(language, { summary = true }):await(function(err)
				if err then
					error(err, vim.log.levels.ERROR)
				else
					vim.treesitter.start(args.buf)
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end)
		end -- }}}
	end,
})

vim.schedule(function()
	local required_parsers = vim.tbl_filter(function(parser)
		return not vim.list_contains(require("nvim-treesitter").get_installed(), parser)
	end, {
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
	if not vim.tbl_isempty(required_parsers) then
		require("nvim-treesitter").install(required_parsers, { summary = true })
	end
end)

-- vim: foldmethod=marker
