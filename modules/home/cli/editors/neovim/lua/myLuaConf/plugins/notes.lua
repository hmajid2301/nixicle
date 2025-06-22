return {
	{
		"obsidian.nvim",
		for_cat = "general.notes",
		event = "DeferredUIEnter",
		after = function(plugin)
			require("obsidian").setup({})
		end,
	},
}
