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
		dependencies = { -- optional packages
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-neotest/neotest-go",
			"nvim-neotest/neotest-python",
			"marilari88/neotest-vitest",
		},
		opts = {
			goimport = "goimport",
			gofmt = "goimports",
		},
	},
}
