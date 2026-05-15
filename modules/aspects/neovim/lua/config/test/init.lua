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
			vim.cmd.packadd("nvim-dap")
			vim.cmd.packadd("nvim-dap-go")
			vim.cmd.packadd("nvim-coverage")
			vim.cmd.packadd("neotest-golang")
			vim.cmd.packadd("plenary.nvim")
		end,
		after = function(plugin)
			require("neotest").setup({
				adapters = {
					require("neotest-golang")({
						go_test_args = {
							"-v",
							"-count=1",
							"-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out",
						},
						go_list_args = {},
						runner = "gotestsum",
						log_level = vim.log.levels.DEBUG,
						warn_test_name_dupes = false,
					}),
				},
				output = { open_on_run = true },
				discovery = {
					enabled = true,
					concurrent = 10,
				},
			})

			local neotest = require("neotest")

			vim.keymap.set("n", "<leader>tt", function()
				neotest.run.run(vim.fn.expand("%"))
			end, { desc = "Test: Run all in current file" })
			vim.keymap.set("n", "<leader>tT", function()
				neotest.run.run(vim.uv.cwd())
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

			vim.keymap.set("n", "<leader>tc", function()
				require("coverage").load()
				require("coverage").toggle()
			end, { desc = "Test: Toggle coverage" })
			vim.keymap.set("n", "<leader>tC", function()
				require("coverage").summary()
			end, { desc = "Test: Coverage summary" })
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
				lang = {
					go = {
						coverage_file = vim.fn.getcwd() .. "/coverage.out",
					},
				},
				signs = {
					covered = { hl = "CoverageCovered", text = "▎" },
					uncovered = { hl = "CoverageUncovered", text = "▎" },
				},
				summary = {
					min_coverage = 80.0,
				},
			})
		end,
	},
})
