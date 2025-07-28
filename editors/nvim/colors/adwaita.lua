vim.cmd.highlight("clear")

if vim.g.syntax_on == 1 then
	vim.cmd.syntax("reset")
end

local color_map = {
	["#004c73"] = "#1e78e4",
	["#005523"] = "#2ec27e",
	["#007373"] = "#0ab9dc",
	["#470045"] = "#9841bb",
	["#590008"] = "#c01c28",
	["#6b5300"] = "#f5c211",
	["#8cf8f7"] = "#4fd2fd",
	["#a6dbff"] = "#51a1ff",
	["#b3f6c0"] = "#57e389",
	["#fce094"] = "#f8e45c",
	["#ffc0b9"] = "#ed333b",
	["#ffcaff"] = "#c061cb",
	["#07080d"] = "#000000",
	["#14161b"] = "#1d1d20",
	["#2c2e33"] = "#2c2e33", -- Identical
	["#4f5258"] = "#5e5c64",
	["#9b9ea4"] = "#9b9ea4", -- Identical
	["#c4c6cd"] = "#c0bfbc",
	["#e0e2ea"] = "#ffffff",
	["#eef1f8"] = "#ffffff",
	["#ff0000"] = "#ff0000", -- Identical
	["#000000"] = "#000000", -- Identical
}

local colorscheme = require("mini.colors").get_colorscheme():color_modify(function(color_name)
	return assert(color_map[color_name], color_name .. " not in color map")
end)

colorscheme.name = "adwaita"
colorscheme:apply()
