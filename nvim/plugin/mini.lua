vim.pack.add({ "https://github.com/nvim-mini/mini.nvim" })

-- {{{ mini.files
require("mini.files").setup({ content = { prefix = function() end } })
vim.keymap.set("n", "<leader>f", function()
	MiniFiles.open(vim.api.nvim_buf_get_name(0))
end, { desc = "Open file explorer" }) -- }}}

vim.schedule(function()
	local function nmap(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { desc = desc })
	end
	-- {{{ mini.git
	require("mini.git").setup() -- }}}
	-- {{{ mini.diff
	require("mini.diff").setup()
	nmap("zV", MiniDiff.toggle_overlay, "Toggle diff overlay in buffer") -- }}}
	-- {{{ mini.bufremove
	require("mini.bufremove").setup()
	nmap("<leader>q", MiniBufremove.delete, "Delete buffer") -- }}}
	-- {{{ mini.trailspace
	require("mini.trailspace").setup()
	vim.api.nvim_create_user_command("Trim", MiniTrailspace.trim, { desc = "Trim trailing whitespace" }) -- }}}
	-- {{{ mini.bracketed
	require("mini.bracketed").setup({
		-- Disable every mapping except [x, ]x etc.
		buffer = { suffix = "" },
		comment = { suffix = "" },
		diagnostic = { suffix = "" },
		file = { suffix = "" },
		indent = { suffix = "" },
		jump = { suffix = "" },
		location = { suffix = "" },
		oldfile = { suffix = "" },
		quickfix = { suffix = "" },
		treesitter = { suffix = "" },
		undo = { suffix = "" },
		window = { suffix = "" },
		yank = { suffix = "" },
	}) -- }}}
	-- {{{ mini.pick
	local pick = require("mini.pick")
	pick.setup({ source = { show = pick.default_show } })
	require("mini.extra").setup()
	vim.ui.select = MiniPick.ui_select

	local builtin = MiniPick.builtin
	local extra = MiniExtra.pickers
	nmap("<leader>/", function()
		return extra.buf_lines({ scope = "current" }, {})
	end, "Search buffer (fuzzy)")
	nmap("<leader><leader>", builtin.buffers, "Search open buffers")
	nmap("<leader>s.", builtin.resume, "Resume previous picker")
	nmap("<leader>s/", extra.buf_lines, "Search open buffers (fuzzy)")
	nmap("<leader>sf", builtin.files, "Search files")
	nmap("<leader>sg", builtin.grep_live, "Search by grep")
	nmap("<leader>sh", builtin.help, "Search help")
	nmap("<leader>sr", extra.oldfiles, "Search recent files") -- }}}
end)
