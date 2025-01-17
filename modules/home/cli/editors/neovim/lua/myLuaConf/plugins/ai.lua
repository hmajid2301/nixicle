return {
	{
		"CopilotChat.nvim",
		for_cat = "general.ai",
		keys = {
			{ "<leader>ac", mode = { "n" }, desc = "Toggle Copilot Chat" },
		},
		cmd = { "CopilotChat" },
		-- event = "",
		-- ft = "",
		-- colorscheme = "",
		load = function(name)
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			require("CopilotChat").setup({})
			vim.keymap.set("n", "<leader>ac", "<cmd>CopilotChat<cr>", { desc = "Toggle Copilot Chat" })
		end,
	},
}
