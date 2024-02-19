local wezterm = require("wezterm")
return {
	color_scheme = "Catppuccin Mocha",
	default_prog = { "fish" },
	font = wezterm.font_with_fallback({
		"MonoLisa Nerd Font",
		"Joypixels",
		"Noto Color Emoji",
	}),
	font_size = 14.0,
	enable_tab_bar = false,
	-- term = "wezterm",
	-- set_environment_variables = {
	-- 	TERMINFO_DIRS = "/home/haseebmajid/.nix-profile/share/terminfo",
	-- },
	hyperlink_rules = wezterm.default_hyperlink_rules(),
	window_padding = {
		left = 20,
		right = 20,
		top = 20,
		bottom = 20,
	},
	keys = {
		{
			key = "t",
			mods = "SUPER",
			action = wezterm.action.DisableDefaultAssignment,
		},
	},
}
