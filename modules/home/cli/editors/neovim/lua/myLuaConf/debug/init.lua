require("lze").load({
	{
		"nvim-dap",
		-- NOTE: I dont want to figure out mason tools installer for this, so I only enabled debug if nix loaded config
		for_cat = "debug",
		keys = {
			{ "<leader>dc", desc = "Debug: Start/Continue" },
			{ "<F5>", desc = "Debug: Start/Continue" },
			{ "<F1>", desc = "Debug: Step Into" },
			{ "<F2>", desc = "Debug: Step Over" },
			{ "<F3>", desc = "Debug: Step Out" },
			{ "<leader>db", mode = { "n" }, desc = "Debug: Toggle Breakpoint" },
			{ "<leader>dp", mode = { "n" }, desc = "Debug: Pause" },
			{ "<leader>dl", mode = { "n" }, desc = "Debug: Run the last config" },
			{ "<leader>ds", mode = { "n" }, desc = "Debug: Focused Session" },
			{ "<leader>dr", mode = { "n" }, desc = "Debug: Restart" },
			{ "<leader>dt", mode = { "n" }, desc = "Debug: Stop" },
			{ "<leader>dC", mode = { "n" }, desc = "Debug: Run to cursor" },
			{ "<leader>dB", mode = { "n" }, desc = "Debug: Set Breakpoint" },
			{ "<leader>dv", mode = { "n" }, desc = "Debug: Toggle Scopes" },
			{ "<leader>dV", mode = { "n" }, desc = "Debug: Toggle variables under cursor" },
			{ "<leader>td", mode = { "n" }, desc = "Test: Debug nearest" },
		},
		-- colorscheme = "",
		load = (require("nixCatsUtils").isNixCats and function(name)
			vim.cmd.packadd(name)
		end) or function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("mason-nvim-dap.nvim")
		end,
		after = function(plugin)
			local dap, dv = require("dap"), require("dap-view")

			dap.listeners.before.attach["dap-view-config"] = function()
				dv.open()
			end
			dap.listeners.before.launch["dap-view-config"] = function()
				dv.open()
			end
			dap.listeners.before.event_terminated["dap-view-config"] = function()
				dv.close()
			end
			dap.listeners.before.event_exited["dap-view-config"] = function()
				dv.close()
			end

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

			vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
			vim.keymap.set("n", "<F6>", dap.step_into, { desc = "Debug: Step Into" })
			vim.keymap.set("n", "<F7>", dap.step_over, { desc = "Debug: Step Over" })
			vim.keymap.set("n", "<F8>", dap.step_out, { desc = "Debug: Step Out" })

			vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
			vim.keymap.set("n", "<leader>dr", function()
				dap.disconnect()
				dap.close()
				dap.run_last()
			end, { desc = "Debug: Restart" })
			vim.keymap.set("n", "<leader>dp", dap.pause, { desc = "Debug: Pause" })
			vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Debug: Run the last config" })
			vim.keymap.set("n", "<leader>ds", dap.session, { desc = "Debug: Focused Session" })
			vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Debug: Stop" })
			vim.keymap.set("n", "<leader>dC", dap.run_to_cursor, { desc = "Debug: Run to cursor" })
			vim.keymap.set("n", "<leader>dB", function()
				dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, { desc = "Debug: Set Breakpoint (with condition)" })

			local dap_widgets = require("dap.ui.widgets")

			local debug_widgets = {
				scopes = nil,
				hover = nil,
			}

			local function create_scopes_widget()
				return dap_widgets.centered_float(dap_widgets.scopes, {
					border = "rounded",
					width = 200,
					height = 25,
				})
			end

			local function create_hover_widget()
				return dap_widgets.hover(nil, { border = "rounded" })
			end

			local function safe_toggle(widget_type, creator_fn)
				return function()
					local current = debug_widgets[widget_type]

					-- Close if exists
					if current then
						pcall(function()
							-- Close window and clear buffer directly
							if current.winid and vim.api.nvim_win_is_valid(current.winid) then
								vim.api.nvim_win_close(current.winid, true)
							end
							if current.bufnr and vim.api.nvim_buf_is_valid(current.bufnr) then
								vim.api.nvim_buf_delete(current.bufnr, { force = true })
							end
						end)
						debug_widgets[widget_type] = nil
						return
					end

					-- Create and open new widget
					local new_widget = creator_fn()
					new_widget.open()
					debug_widgets[widget_type] = new_widget

					-- Track window closure
					vim.api.nvim_create_autocmd("WinClosed", {
						pattern = tostring(new_widget.winid),
						once = true,
						callback = function()
							debug_widgets[widget_type] = nil
						end,
					})
				end
			end

			-- Keymaps
			vim.keymap.set(
				"n",
				"<leader>dv",
				safe_toggle("scopes", create_scopes_widget),
				{ desc = "Debug: Toggle Scopes" }
			)
			vim.keymap.set(
				"n",
				"<leader>dV",
				safe_toggle("hover", create_hover_widget),
				{ desc = "Debug: Toggle Variables" }
			)
		end,
	},
	{
		"nvim-dap-view",
		for_cat = "debug",
		on_plugin = { "nvim-dap" },
		after = function(plugin)
			require("dap-view").setup({
				windows = {
					terminal = {
						hide = { "go" },
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
				delve = { build_flags = "-tags=unit,integration,e2e,bdd,dind", path = "dlv", port = "40000" },
			})
		end,
	},

	{
		"debugmaster-nvim",
		for_cat = "debug",
		on_plugin = { "nvim-dap" },
		after = function(plugin)
			require("debugmaster").setup({})
		end,
	},
})
