return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
			config = function()
				require("telescope").load_extension("fzf")
			end,
			"debugloop/telescope-undo.nvim",
			"mrcjkb/telescope-manix",
		},
		config = function()
			require("telescope").load_extension("manix")
			require("telescope").load_extension("undo")
		end,
		opts = function(_, opts)
			opts.extensions = {
				undo = {},
			}
		end,
	},
}
