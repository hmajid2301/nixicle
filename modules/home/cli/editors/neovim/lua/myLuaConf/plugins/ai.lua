return {
	{
		"sidekick.nvim",
		for_cat = "general.ai",
		event = "DeferredUIEnter",
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
