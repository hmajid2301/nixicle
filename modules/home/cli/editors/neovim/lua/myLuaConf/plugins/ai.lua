return {
	{
		"CopilotChat.nvim",
		for_cat = "general.ai",
		keys = {
			{ "<leader>ac", mode = { "n" }, desc = "Toggle Copilot Chat" },
		},
		cmd = { "CopilotChat", "Copilot" },
		load = function(name)
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			require("CopilotChat").setup({})
			vim.keymap.set("n", "<leader>ac", "<cmd>CopilotChat<cr>", { desc = "Toggle Copilot Chat" })
		end,
	},
	{
		"avante.nvim",
		for_cat = "general.ai",
		cmd = { "AvanteChat", "AvanteAsk" },
		load = function(name)
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			require("avante").setup({})
		end,
	},
}
