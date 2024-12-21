-- Pull in the wezterm api
local wezterm = require("wezterm")

local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

-----* Make it not slow *-----
config.front_end = "WebGpu"

-----* Maximize window on startup *-----
local initial_scale = 2.5
config.initial_rows = math.ceil(initial_scale * 24)
config.initial_cols = math.ceil(initial_scale * 80)

-----* Colorcheme *-----
local cat = wezterm.color.get_builtin_schemes()["Catppuccin Mocha"]
cat.background = "#000000"
cat.tab_bar.background = "#040404"
cat.tab_bar.inactive_tab.bg_color = "#0f0f0f"
cat.tab_bar.new_tab.bg_color = "#080808"
config.color_schemes = {
	["Blackppuccin"] = cat,
}
config.color_scheme = "Blackppuccin"

-----* Font *-----
config.font = wezterm.font_with_fallback({
	"IosevkaTerm Nerd Font",
	"Sarasa Term",
})
config.font_size = 17
config.term = "wezterm"
config.window_decorations = "RESIZE"

-----* Tabs *-----
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

-----* Shell *----
config.default_prog = { "/usr/bin/nu" }

-----* Keys *-----
local function is_inside_vim(pane)
	local tty = pane:get_tty_name()
	if tty == nil then
		return false
	end

	local success, _, _ = wezterm.run_child_process({
		"sh",
		"-c",
		"ps -o state= -o comm= -t"
			.. wezterm.shell_quote_arg(tty)
			.. " | "
			.. "grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?)(diff)?$'",
	})

	return success
end
local function is_outside_vim(pane)
	return not is_inside_vim(pane)
end
local function bind_if(cond, key, mods, action)
	local function callback(win, pane)
		if cond(pane) then
			win:perform_action(action, pane)
		else
			win:perform_action(wezterm.action.SendKey({ key = key, mods = mods }), pane)
		end
	end

	return { key = key, mods = mods, action = wezterm.action_callback(callback) }
end

config.keys = {
	{
		key = "Enter",
		mods = "CTRL",
		action = wezterm.action.SplitHorizontal,
	},
	{
		key = "E",
		mods = "CTRL|SHIFT",
		action = wezterm.action.PromptInputLine({
			description = "Enter new name for tab",
			action = wezterm.action_callback(function(window, pane, line)
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of text they wrote
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
	bind_if(is_outside_vim, "h", "CTRL", wezterm.action.ActivatePaneDirection("Left")),
	bind_if(is_outside_vim, "l", "CTRL", wezterm.action.ActivatePaneDirection("Right")),
	bind_if(is_outside_vim, "j", "CTRL", wezterm.action.ActivatePaneDirection("Down")),
	bind_if(is_outside_vim, "k", "CTRL", wezterm.action.ActivatePaneDirection("Up")),
}

return config
