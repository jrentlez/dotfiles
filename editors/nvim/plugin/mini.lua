vim.pack.add({ "https://github.com/echasnovski/mini.nvim" })

-- mini.notify ---------------------------------------------------------

require("mini.notify").setup()
vim.notify = MiniNotify.make_notify()

-- mini.files ----------------------------------------------------------

require("mini.files").setup({ content = { prefix = function() end } })

vim.schedule(function()
	-- Keymaps -------------------------------------------------------------

	local function nmap(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { desc = desc })
	end

	-- mini.files ----------------------------------------------------------

	nmap("<leader>f", function()
		MiniFiles.open(vim.api.nvim_buf_get_name(0))
	end, "Open file explorer")

	-- mini.bufremove ------------------------------------------------------

	require("mini.bufremove").setup()
	nmap("<leader>q", MiniBufremove.delete, "Delete buffer")

	-- mini.trailspace -----------------------------------------------------

	require("mini.trailspace").setup()
	vim.api.nvim_create_user_command("Trim", MiniTrailspace.trim, { desc = "Trim trailing whitespace" })

	-- mini.diff -----------------------------------------------------------

	require("mini.diff").setup({
		mappings = {
			apply = "<leader>ha",
			reset = "<leader>hr",
		},
	})
	nmap("<leader>ho", MiniDiff.toggle_overlay, "Hunks overlay")

	-- mini.git -----------------------------------------------------------

	require("mini.git").setup()
	nmap("<leader>hi", MiniGit.show_at_cursor, "Show line history")

	-- mini.pick -----------------------------------------------------------

	local pick = require("mini.pick")
	pick.setup({ source = { show = pick.default_show } })
	vim.ui.select = MiniPick.ui_select

	local builtin = MiniPick.builtin
	local extra = require("mini.extra").pickers
	nmap("<leader>/", function()
		return extra.buf_lines({ scope = "current" }, {})
	end, "Search buffer (fuzzy)")
	nmap("<leader><leader>", builtin.buffers, "Search open buffers")
	nmap("<leader>s.", builtin.resume, "Resume previous picker")
	nmap("<leader>s/", extra.buf_lines, "Search open buffers (fuzzy)")
	nmap("<leader>sf", builtin.files, "Search files")
	nmap("<leader>sg", builtin.grep_live, "Search by grep")
	nmap("<leader>sh", function()
		return builtin.help({ default_split = "vertical" })
	end, "Search help")
	nmap("<leader>sp", function()
		local all = vim.tbl_extend("error", builtin, extra)
		MiniPick.start({
			source = {
				items = vim.tbl_keys(all),
				name = "Pickers",
				choose = function(picker)
					all[picker]()
				end,
			},
		})
	end, "Search pickers")
	nmap("<leader>sr", extra.oldfiles, "Search recent files")

	-- mini.hipatterns -----------------------------------------------------

	require("mini.hipatterns").setup({
		highlighters = {
			hex_color = require("mini.hipatterns").gen_highlighter.hex_color(),
		},
	})

	-- mini.clue -----------------------------------------------------------

	local miniclue = require("mini.clue")
	miniclue.setup({
		triggers = {
			-- Leader triggers
			{ mode = "n", keys = "<Leader>" },
			{ mode = "x", keys = "<Leader>" },
			-- Built-in completion
			{ mode = "i", keys = "<C-x>" },
			-- `g` key
			{ mode = "n", keys = "g" },
			{ mode = "x", keys = "g" },
			-- Marks
			{ mode = "n", keys = "'" },
			{ mode = "n", keys = "`" },
			{ mode = "x", keys = "'" },
			{ mode = "x", keys = "`" },
			-- Registers
			{ mode = "n", keys = '"' },
			{ mode = "x", keys = '"' },
			{ mode = "i", keys = "<C-r>" },
			{ mode = "c", keys = "<C-r>" },
			-- Window commands
			{ mode = "n", keys = "<C-w>" },
			-- `z` key
			{ mode = "n", keys = "z" },
			{ mode = "x", keys = "z" },
		},
		clues = {
			miniclue.gen_clues.builtin_completion(),
			miniclue.gen_clues.g(),
			miniclue.gen_clues.marks(),
			miniclue.gen_clues.registers(),
			miniclue.gen_clues.windows(),
			miniclue.gen_clues.z(),
			-- Enhance this by adding descriptions for <Leader> mapping groups
			{ mode = "n", keys = "<leader>s", desc = "+Search" },
			{ mode = "n", keys = "<leader>h", desc = "+Hunks" },
			{ mode = "v", keys = "<leader>h", desc = "+Hunks" },
			{ mode = "n", keys = "gq", desc = "+Quickfix" },
		},
		window = { delay = vim.o.timeoutlen },
	})
end)
