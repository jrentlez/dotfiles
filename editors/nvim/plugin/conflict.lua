---@module "mini.deps"

local add, now = MiniDeps.add, MiniDeps.now

now(function()
	add({ source = "akinsho/git-conflict.nvim", checkout = "v2.1.0", monitor = "v2.1.0" })

	require("git-conflict").setup({
		debug = false,
		default_mappings = false, -- disable buffer local mapping created by this plugin
		default_commands = false, -- disable commands created by this plugin
		disable_diagnostics = true, -- This will disable the diagnostics in a buffer whilst it is conflicted
		list_opener = "copen", -- command or function to open the conflicts list
		highlights = {
			current = "DiffText",
			incoming = "DiffAdd",
			ancestor = "DiffChange",
		},
	})

	vim.api.nvim_create_autocmd("User", {
		pattern = "GitConflictDetected",
		---@param args {buf: number}
		callback = function(args)
			vim.keymap.set("n", "grh", function()
				vim.ui.select({ "ours", "theirs", "both", "base", "none" }, {
					prompt = "Select a variant to keep",
					---@param item ConflictSide
					format_item = function(item)
						return "Keep " .. item
					end,
				}, function(item, _)
					if item then
						require("git-conflict").choose(item)
					end
				end)
			end, { buffer = args.buf, desc = "Resolve conflict" })

			vim.keymap.set("n", "gC", function()
				require("git-conflict").find_next("ours")
			end, { buffer = args.buf, desc = "Goto next conflict" })
		end,
	})
end)
