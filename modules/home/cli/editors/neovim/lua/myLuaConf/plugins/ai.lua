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
			vim.cmd.packadd("copilot.lua")
		end,
		after = function(plugin)
			require("copilot").setup({})
			require("CopilotChat").setup({
				model = "gpt-4o",
			})
			vim.keymap.set("n", "<leader>ac", "<cmd>CopilotChat<cr>", { desc = "Toggle Copilot Chat" })
		end,
	},
	{
		"avante.nvim",
		for_cat = "general.ai",
		cmd = { "AvanteChat", "AvanteAsk" },
		keys = {
			{ "<leader>aa", mode = { "n" }, desc = "Toggle Avanate" },
		},
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("mcphub.nvim")
		end,
		after = function(plugin)
			require("avante").setup({
				provider = "copilot",
				hints = { enabled = false },
				custom_tools = function()
					return {
						require("mcphub.extensions.avante").mcp_tool(),
					}
				end,
				system_prompt = function()
					local hub = require("mcphub").get_hub_instance()
					return hub and hub:get_active_servers_prompt() or ""
				end,
			})
		end,
	},
	{
		"mcphub.nvim",
		for_cat = "general.ai",
		cmd = { "MCPHub" },
		after = function(plugin)
			require("mcphub").setup({})
		end,
	},
}
