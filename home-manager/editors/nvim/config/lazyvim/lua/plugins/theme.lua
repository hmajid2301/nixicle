return {
	{
		"catppuccin/nvim",
		lazy = false,
		name = "catppuccin",
		priority = 1000,
		opts = {
			flavour = "frappe",
			integrations = {
				alpha = true,
				integrations = {
					barbecue = {
						dim_dirname = true,
						bold_basename = true,
						dim_context = false,
					},
					dap = { enabled = true, enable_ui = true },
					harpoon = true,
					gitsigns = true,
					mason = true,
          markdown = true,
					neotree = true,
					neotest = true,
					noice = true,
					notify = true,
					semantic_tokens = true,
					symbols_outline = true,
					treesitter = true,
					treesitter_context = true,
					telescope = {
						enabled = true,
						style = "nvchad",
					},
					lsp_trouble = true,
					which_key = true,
				},
			},
		},
	},

	-- Configure LazyVim to load theme
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "catppuccin",
		},
	},
}
