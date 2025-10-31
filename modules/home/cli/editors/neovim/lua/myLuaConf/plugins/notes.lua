return {
	{
		"obsidian.nvim",
		for_cat = "general.notes",
		event = "DeferredUIEnter",
		after = function(plugin)
			require("obsidian").setup({})
		end,
	},
	{
		"markview.nvim",
		for_cat = "general.notes",
		event = "BufReadPre",
		after = function(plugin)
			require("markview").setup({})
		end,
	},
}
