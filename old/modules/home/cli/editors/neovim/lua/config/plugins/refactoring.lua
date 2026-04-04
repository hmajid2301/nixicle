return {
	{
		"refactoring.nvim",
		for_cat = "general.editor",
		keys = {
			{ "<leader>re", mode = { "x" }, desc = "Refactor extract" },
			{ "<leader>rf", mode = { "x" }, desc = "Refactor extract to file" },
			{ "<leader>rv", mode = { "x" }, desc = "Refactor variable" },
			{ "<leader>ri", mode = { "x", "n" }, desc = "Refactor inline variable" },
			{ "<leader>rI", mode = { "n" }, desc = "Refactor inline function" },
			{ "<leader>rb", mode = { "n" }, desc = "Refactor extract block" },
			{ "<leader>rbf", mode = { "n" }, desc = "Refactor extract block to file" },
		},
		load = function(name)
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			require("refactoring").setup({})

			vim.keymap.set("x", "<leader>re", "<cmd>Refactor extract<cr>", { desc = "Refactor extract" })
			vim.keymap.set(
				"x",
				"<leader>rf",
				"<cmd>Refactor extract_to_file<cr>",
				{ desc = "Refactor extract to file" }
			)
			vim.keymap.set("x", "<leader>rv", "<cmd>Refactor extract_var<cr>", { desc = "Refactor variable" })
			vim.keymap.set(
				{ "x", "n" },
				"<leader>ri",
				"<cmd>Refactor inline_var<cr>",
				{ desc = "Refactor inline variable" }
			)
			vim.keymap.set("n", "<leader>rI", "<cmd>Refactor inline_func<cr>", { desc = "Refactor inline function" })
			vim.keymap.set("n", "<leader>rb", "<cmd>Refactor extract_block<cr>", { desc = "Refactor extract block" })
			vim.keymap.set(
				"n",
				"<leader>rbf",
				"<cmd>Refactor extract_block_to_file<cr>",
				{ desc = "Refactor extract block to file" }
			)
		end,
	},
}
