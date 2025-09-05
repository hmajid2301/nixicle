return {
	{
		"mcphub.nvim",
		for_cat = "general.ai",
		cmd = { "MCPHub" },
		after = function(plugin)
			require("mcphub").setup({})
		end,
	},
}
