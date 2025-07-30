vim.cmd.highlight("clear")

if vim.g.syntax_on == 1 then
	vim.cmd.syntax("reset")
end

vim.g.colors_name = "terminal"

vim.api.nvim_set_hl(0, "Normal", { force = true })
