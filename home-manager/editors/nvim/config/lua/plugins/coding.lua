return {
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-emoji",
		},
		opts = function(_, opts)
			local cmp = require("cmp")

			opts.mapping = vim.tbl_extend("force", opts.mapping, {
				["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
				["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
				["<C-Space>"] = cmp.mapping.confirm({ select = true }),
				["<CR>"] = cmp.config.disable,
			})
		end,
	},
	{
		"echasnovski/mini.splitjoin",
		main = "mini.splitjoin",
		keys = {
			{
				"<leader>sj",
				"<cmd>lua MiniSplitjoin.join()<CR>",
				mode = { "n", "x" },
				desc = "Join arguments",
			},
			{
				"<leader>sk",
				"<cmd>lua MiniSplitjoin.split()<CR>",
				mode = { "n", "x" },
				desc = "Split arguments",
			},
		},
		opts = {
			mappings = { toggle = "" },
		},
	},
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/neotest-go",
		},
		keys = {
			{ "<leader>ta", "<cmd>lua require('neotest').run.attach()<cr>", desc = "Attach to the nearest test" },
			{ "<leader>tl", "<cmd>lua require('neotest').run.run_last()<cr>", desc = "Toggle Test Summary" },
			{
				"<leader>to",
				"<cmd>lua require('neotest').output_panel.toggle()<cr>",
				desc = "Toggle Test Output Panel",
			},
			{ "<leader>tp", "<cmd>lua require('neotest').run.stop()<cr>", desc = "Stop the nearest test" },
			{ "<leader>ts", "<cmd>lua require('neotest').summary.toggle()<cr>", desc = "Toggle Test Summary" },
			{ "<leader>tt", "<cmd>lua require('neotest').run.run()<cr>", desc = "Run the nearest test" },
			{
				"<leader>tT",
				"<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<cr>",
				desc = "Run test the current file",
			},
		},
		opts = {
			adapters = {
				["neotest-go"] = {
					-- Here we can set options for neotest-go, e.g.
					-- args = { "-tags=integration" }
				},
			},
		},
	},
}
