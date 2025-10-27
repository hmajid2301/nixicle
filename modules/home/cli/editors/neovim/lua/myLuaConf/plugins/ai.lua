return {
	{
		"mcphub.nvim",
		for_cat = "general.ai",
		cmd = { "MCPHub" },
		after = function(plugin)
			require("mcphub").setup({})
		end,
	},
	{
		"sidekick-nvim",
		for_cat = "general.ai",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			require("sidekick").setup({
				nes = {
					enabled = false,
				},
				cli = {
					mux = {
						backend = "zellij",
						enabled = true,
					},
				},
			})
		end,
	},
}
