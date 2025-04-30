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
		after = function(plugin)
			require("avante").setup({
				provider = "copilot",
				hints = { enabled = false },
				custom_tools = {
					{
						name = "run_go_tests", -- Unique name for the tool
						description = "Run Go unit tests and return results", -- Description shown to AI
						command = "go test -v ./...", -- Shell command to execute
						param = { -- Input parameters (optional)
							type = "table",
							fields = {
								{
									name = "target",
									description = "Package or directory to test (e.g. './pkg/...' or './internal/pkg')",
									type = "string",
									optional = true,
								},
							},
						},
						returns = { -- Expected return values
							{
								name = "result",
								description = "Result of the fetch",
								type = "string",
							},
							{
								name = "error",
								description = "Error message if the fetch was not successful",
								type = "string",
								optional = true,
							},
						},
						func = function(params, on_log, on_complete) -- Custom function to execute
							local target = params.target or "./..."
							return vim.fn.system(string.format("go test -v %s", target))
						end,
					},
				},
			})
		end,
	},
}
