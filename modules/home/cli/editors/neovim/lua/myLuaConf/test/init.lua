require("lze").load({
	{
		"neotest",
		for_cat = "test",
		keys = {
			{ "<leader>tt", mode = { "n" }, desc = "Test: Run all in current file" },
			{ "<leader>tT", mode = { "n" }, desc = "Test: Run all in all files" },
			{ "<leader>tS", mode = { "n" }, desc = "Test: Stop" },
			{ "<leader>ts", mode = { "n" }, desc = "Test: Toggle Summary" },
			{ "<leader>tr", mode = { "n" }, desc = "Test: Run Nearest" },
			{ "<leader>to", mode = { "n" }, desc = "Test: Show Output" },
			{ "<leader>td", mode = { "n" }, desc = "Test: Debug nearest" },
			{ "<leader>tO", mode = { "n" }, desc = "Test: Toggle output" },
		},
		-- colorscheme = "",
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("neotest-golang")
		end,
		after = function(plugin)
			require("neotest").setup({
				adapters = {
					require("neotest-golang")({
						go_test_args = { "-v", "-x", "-count=1", "-tags=integration" },
						go_list_args = { "-tags=integration" },
						dap_go_opts = {
							delve = {
								build_flags = { "-tags=integration" },
							},
						},
					}),
				},
				output = { open_on_run = true },
			})

			local neotest = require("neotest")

			vim.keymap.set("n", "<leader>tt", function()
				neotest.run.run(vim.fn.expand("%"))
			end, { desc = "Test: Run all in current file" })
			vim.keymap.set("n", "<leader>tT", function()
				neotest.run.run(vim.loop.cwd())
			end, { desc = "Test: Run all in all files" })
			vim.keymap.set("n", "<leader>tS", neotest.run.stop, { desc = "Test: Stop" })
			vim.keymap.set("n", "<leader>ts", neotest.summary.toggle, { desc = "Test: Toggle Summary" })
			vim.keymap.set("n", "<leader>tr", neotest.run.run, { desc = "Test: Run Nearest" })
			vim.keymap.set("n", "<leader>to", function()
				neotest.output.open({ enter = true, auto_close = true })
			end, { desc = "Test: Show Output" })
			vim.keymap.set("n", "<leader>td", function()
				neotest.run.run({ suite = false, strategy = "dap" })
			end, { desc = "Test: Debug nearest" })
			vim.keymap.set("n", "<leader>tO", function()
				neotest.output_panel.toggle()
			end, { desc = "Test: Toggle output" })
		end,
	},
	{
		"nvim-coverage",
		for_cat = "test",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			require("coverage").setup({
				auto_reload = true,
			})
		end,
	},
})
