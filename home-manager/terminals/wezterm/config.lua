local wezterm = require("wezterm")
return {
	color_scheme = "Catppuccin Mocha",
	default_prog = { "fish" },
	font = wezterm.font("MonoLisa Nerd Font"),
	font_size = 14.0,
	enable_tab_bar = false,
	term = "wezterm",
	keys = {
		{
			key = "t",
			mods = "SUPER",
			action = wezterm.action.DisableDefaultAssignment,
		},
	},
}
