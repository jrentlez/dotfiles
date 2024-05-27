local add, later = MiniDeps.add, MiniDeps.later

later(function()
	add({
		source = "barrett-ruth/live-server.nvim",
		hooks = {
			post_checkout = function()
				vim.system({ "npm", "install", "-g", "live-server" })
			end,
		},
	})

	require("live-server").setup()
end)
