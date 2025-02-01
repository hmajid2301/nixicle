require("lze").load({
	{
		"nvim-dap",
		-- NOTE: I dont want to figure out mason tools installer for this, so I only enabled debug if nix loaded config
		for_cat = "debug",
		-- cmd = { "" },
		-- event = "",
		-- ft = "",
		keys = {
			{ "<leader>dc", desc = "Debug: Start/Continue" },
			{ "<F5>", desc = "Debug: Start/Continue" },
			{ "<F1>", desc = "Debug: Step Into" },
			{ "<F2>", desc = "Debug: Step Over" },
			{ "<F3>", desc = "Debug: Step Out" },
			{ "<leader>b", desc = "Debug: Toggle Breakpoint" },
			{ "<leader>B", desc = "Debug: Set Breakpoint" },
			{ "<leader>db", mode = { "n" }, desc = "Debug: Toggle Breakpoint" },
			{ "<leader>dp", mode = { "n" }, desc = "Debug: Pause" },
			{ "<leader>dl", mode = { "n" }, desc = "Debug: Run the last config" },
			{ "<leader>ds", mode = { "n" }, desc = "Debug: Focused Session" },
			{ "<leader>dt", mode = { "n" }, desc = "Debug: Stop" },
			{ "<leader>dC", mode = { "n" }, desc = "Debug: Run to cursor" },
			{ "<leader>dB", mode = { "n" }, desc = "Debug: Set Breakpoint" },
			{ "<leader>dv", mode = { "n" }, desc = "Debug: Toggle Scopes" },
			{ "<leader>td", mode = { "n" }, desc = "Test: Debug nearest" },
		},
		-- colorscheme = "",
		load = (require("nixCatsUtils").isNixCats and function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("nvim-dap")
		end) or function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("nvim-dap")
			vim.cmd.packadd("mason-nvim-dap.nvim")
		end,
		after = function(plugin)
			local dap = require("dap")

			vim.fn.sign_define("DapBreakpoint", { text = " ", texthl = "DapBreakpoint", linehl = "", numhl = "" })
			vim.fn.sign_define(
				"DapBreakpointCondition",
				{ text = " ", texthl = "DapBreakpointCondition", linehl = "", numhl = "" }
			)
			vim.fn.sign_define(
				"DapBreakpointRejected",
				{ text = " ", texthl = "DiagnosticError", linehl = "", numhl = "" }
			)
			vim.fn.sign_define("DapLogPoint", { text = " ", texthl = "DapBreakpoint", linehl = "", numhl = "" })
			vim.fn.sign_define(
				"DapStopped",
				{ text = "󰁕 ", texthl = "DapStopped", linehl = "DapStopped", numhl = "DapStopped" }
			)

			vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Debug: Start/Continue" })
			vim.keymap.set("n", "<leader>dv", function()
				local widgets = require("dap.ui.widgets")
				widgets.centered_float(widgets.scopes, { border = "rounded" })
			end, { desc = "Debug: Toggle DAP Scopes" })
			vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
			vim.keymap.set("n", "<F1>", dap.step_into, { desc = "Debug: Step Into" })
			vim.keymap.set("n", "<F2>", dap.step_over, { desc = "Debug: Step Over" })
			vim.keymap.set("n", "<F3>", dap.step_out, { desc = "Debug: Step Out" })

			vim.keymap.set("n", "<leader>dr", function()
				dap.disconnect()
				dap.close()
				dap.run_last()
			end, { desc = "Debug: Restart" })
			--
			vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
			vim.keymap.set("n", "<leader>dp", dap.pause, { desc = "Debug: Pause" })
			vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Debug: Run the last config" })
			vim.keymap.set("n", "<leader>ds", dap.session, { desc = "Debug: Focused Session" })
			vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Debug: Stop" })
			vim.keymap.set("n", "<leader>dC", dap.run_to_cursor, { desc = "Debug: Run to cursor" })
			vim.keymap.set("n", "<leader>dB", function()
				dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, { desc = "Debug: Set Breakpoint" })
		end,
	},
	{
		"nvim-dap-view",
		for_cat = "debug",
		on_plugin = { "nvim-dap" },
		after = function(plugin)
			require("dap-view").setup({})
		end,
	},
	{
		"nvim-dap-go",
		for_cat = "debug",
		on_plugin = { "nvim-dap" },
		after = function(plugin)
			require("dap-go").setup({
				dap_configurations = { { mode = "remote", name = "Attach remote", request = "attach", type = "go" } },
				delve = { build_flags = "-tags=unit,integration,e2e,bdd,dind", path = "dlv", port = "38697" },
			})
		end,
	},
})
