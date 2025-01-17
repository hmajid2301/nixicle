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
			{ "<F7>", desc = "Debug: See last session result." },
			{ "<leader>db", mode = { "n" }, desc = "Debug: Toggle Breakpoint" },
			{ "<leader>dp", mode = { "n" }, desc = "Debug: Pause" },
			{ "<leader>dl", mode = { "n" }, desc = "Debug: Run the last config" },
			{ "<leader>ds", mode = { "n" }, desc = "Debug: Focused Session" },
			{ "<leader>dt", mode = { "n" }, desc = "Debug: Stop" },
			{ "<leader>dw", mode = { "n" }, desc = "Debug: Hover Widget" },
			{ "<leader>dC", mode = { "n" }, desc = "Debug: Run to cursor" },
			{ "<leader>dB", mode = { "n" }, desc = "Debug: Set Breakpoint" },
			{ "<leader>dut", mode = { "n" }, desc = "Debug: Toggle Types" },
			{ "<leader>td", mode = { "n" }, desc = "Test: Debug nearest" },
		},
		-- colorscheme = "",
		load = (require("nixCatsUtils").isNixCats and function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("nvim-dap")
			vim.cmd.packadd("nvim-dap-ui")
		end) or function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("nvim-dap")
			vim.cmd.packadd("nvim-dap-ui")
			vim.cmd.packadd("mason-nvim-dap.nvim")
		end,
		after = function(plugin)
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
				{ text = "󰁕 ", texthl = "DiagnosticWarn", linehl = "DapStoppedLine", numhl = "DapStoppedLine" }
			)

			local dap = require("dap")
			local dapui = require("dapui")

			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open(1)
			end
			dap.listeners.before.event_terminated["dapui_config"] = dapui.close
			dap.listeners.before.event_exited["dapui_config"] = dapui.close

			vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Debug: Start/Continue" })
			vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
			vim.keymap.set("n", "<F1>", dap.step_into, { desc = "Debug: Step Into" })
			vim.keymap.set("n", "<F2>", dap.step_over, { desc = "Debug: Step Over" })
			vim.keymap.set("n", "<F3>", dap.step_out, { desc = "Debug: Step Out" })
			vim.keymap.set("n", "<F7>", dapui.toggle, { desc = "Debug: See last session result." })

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
			vim.keymap.set("n", "<leader>dut", function()
				local render = dapui.config.render
				render.max_type_length = (render.max_type_length == nil) and 0 or nil
				require("dapui").update_render(render)
			end, { desc = "Debug: Toggle Types" })

			dapui.setup({
				expand_lines = false,
				layouts = {
					{
						elements = { { id = "stacks", size = 0.2 }, { id = "scopes", size = 0.8 } },
						position = "bottom",
						size = 40,
					},
					{ elements = { { id = "repl", size = 1 } }, position = "bottom", size = 30 },
					{
						elements = { { id = "breakpoints", size = 0.5 }, { id = "watches", size = 0.5 } },
						position = "bottom",
						size = 30,
					},
				},
			})
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
