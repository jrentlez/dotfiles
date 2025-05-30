---@module "mini.deps"

local add, later = MiniDeps.add, MiniDeps.later

later(function()
	add({ source = "https://gitlab.com/TungstnBallon/conflict.nvim" })

	vim.keymap.set("n", "gC", function()
		require("conflict").jump_to_next_conflict(nil, nil, true)
	end)

	vim.keymap.set("n", "grn", function()
		vim.ui.select({ "current", "base", "incoming", "none", "both" }, {
			prompt = "Select a variant to keep",
			format_item = function(item)
				return "Keep " .. item
			end,
		}, function(item)
			if item then
				require("conflict").resolve_conflict_at(nil, nil, item)
			end
		end)
		require("conflict").jump_to_next_conflict(nil, nil, true)
	end)
end)
