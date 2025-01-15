local options = {
	base46 = {
		theme = "catppuccin", -- default theme
		hl_add = {},
		hl_override = {
			["@property"] = { fg = "#F38BA8" },
		},
		integrations = {
			"dap",
		},
		changed_themes = {},
		transparency = false,
		theme_toggle = { "catppuccin", "one_light" },
	},

	ui = {
		cmp = {
			lspkind_text = true,
			style = "default", -- default/flat_light/flat_dark/atom/atom_colored
			format_colors = {
				tailwind = true, -- will work for css lsp too
				icon = "󱓻",
			},
		},

		telescope = { style = "borderless" }, -- borderless / bordered

		statusline = {
			enabled = false,
			theme = "minimal", -- default/vscode/vscode_colored/minimal
			-- default/round/block/arrow separators work only for default statusline theme
			-- round and block will work for minimal theme only
			separator_style = "block",
			order = nil,
			modules = nil,
		},

		-- lazyload it when there are 1+ buffers
		tabufline = {
			enabled = false,
		},
	},

	nvdash = {
		load_on_startup = true,
		header = {
			" ▄▄    ▄ ▄▄▄ ▄▄   ▄▄    ▄▄▄▄▄▄▄ ▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ",
			"█  █  █ █   █  █▄█  █  █       █      █       █       █",
			"█   █▄█ █   █       █  █       █  ▄   █▄     ▄█  ▄▄▄▄▄█",
			"█       █   █       █  █     ▄▄█ █▄█  █ █   █ █ █▄▄▄▄▄ ",
			"█  ▄    █   ██     █   █    █  █      █ █   █ █▄▄▄▄▄  █",
			"█ █ █   █   █   ▄   █  █    █▄▄█  ▄   █ █   █  ▄▄▄▄▄█ █",
			"█▄█  █▄▄█▄▄▄█▄▄█ █▄▄█  █▄▄▄▄▄▄▄█▄█ █▄▄█ █▄▄▄█ █▄▄▄▄▄▄▄█",
			"                                                       ",
			"                   Powered By  eovim                 ",
			"                                                       ",
		},

		buttons = {
			{ txt = "  Find File", keys = "ff", cmd = "Telescope find_files" },
			{ txt = "  Recent Files", keys = "fo", cmd = "Telescope oldfiles" },
			{ txt = "󰈭  Find Word", keys = "fw", cmd = "Telescope live_grep" },
			{ txt = "󱥚  Themes", keys = "th", cmd = ":lua require('nvchad.themes').open()" },
			{ txt = "  Mappings", keys = "ch", cmd = "NvCheatsheet" },

			{ txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },

			{
				txt = function()
					return "  I use neovim btw  "
					-- local stats = require("lazy").stats()
					-- local ms = math.floor(stats.startuptime) .. " ms"
					-- return "  Loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms
				end,
				hl = "NvDashFooter",
				no_gap = true,
			},

			{ txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },
		},
	},

	lsp = { signature = true },

	cheatsheet = {
		theme = "grid", -- simple/grid
		excluded_groups = { "terminal (t)", "autopairs", "Nvim", "Opens" }, -- can add group name or with mode
	},

	colorify = {
		enabled = true,
		mode = "virtual", -- fg, bg, virtual
		virt_text = "󱓻 ",
		highlight = { hex = true, lspvars = true },
	},
}

require("cmp").setup(vim.tbl_deep_extend("force", options, require("nvchad.cmp")))

local status, chadrc = pcall(require, "chadrc")
return vim.tbl_deep_extend("force", options, status and chadrc or {})
