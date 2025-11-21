return {
	{
		"nvim-dbee",
		for_cat = "general.editor",
		cmd = { "Dbee" },
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("cmp-dbee")
		end,
		after = function(plugin)
			require("dbee").setup({})
			require("cmp-dbee").setup()
		end,
	},
	{
		"todo-comments.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		after = function(plugin)
			require("todo-comments").setup()
		end,
	},
	{
		"grug-far.nvim",
		for_cat = "general.editor",
		keys = {
			{ "<leader>sr", mode = { "n" }, desc = "Search and replace" },
		},
		after = function(plugin)
			require("grug-far").setup()
			vim.keymap.set("n", "<leader>sr", function()
				require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
			end, { desc = "Search and replace" })
		end,
	},
	{
		"smart-splits.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		after = function(plugin)
			require("smart-splits").setup({
				ignored_buftypes = {
					"nofile",
					"quickfix",
					"prompt",
				},
			})
			vim.keymap.set("n", "<C-h>", require("smart-splits").move_cursor_left, { desc = "Move to left split" })
			vim.keymap.set("n", "<C-j>", require("smart-splits").move_cursor_down, { desc = "Move to below split" })
			vim.keymap.set("n", "<C-k>", require("smart-splits").move_cursor_up, { desc = "Move to above split" })
			vim.keymap.set("n", "<C-l>", require("smart-splits").move_cursor_right, { desc = "Move to right split" })
		end,
	},
	{
		"gx.nvim",
		for_cat = "general.editor",
		cmd = { "Browse" },
		keys = { { "gx", "<cmd>Browse<cr>", mode = { "n", "x" } } },
		init = function()
			vim.g.netrw_nogx = 1
		end,
		after = function(plugin)
			require("gx").setup()
		end,
	},
	{
		"inc-rename.nvim",
		for_cat = "general.editor",
		keys = {
			{ "<leader>rn", mode = { "n" }, desc = "Incremental rename" },
		},
		after = function(plugin)
			require("inc_rename").setup()
			vim.keymap.set("n", "<leader>rn", function()
				return ":IncRename " .. vim.fn.expand("<cword>")
			end, { expr = true, desc = "Incremental rename" })
		end,
	},
	{
		"quicker.nvim",
		for_cat = "general.editor",
		event = { "FileType" },
		ft = { "qf" },
		after = function(plugin)
			require("quicker").setup({
				keys = {
					{
						">",
						function()
							require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
						end,
						desc = "Expand quickfix context",
					},
					{
						"<",
						function()
							require("quicker").collapse()
						end,
						desc = "Collapse quickfix context",
					},
				},
			})
		end,
	},
	{
		"templ-goto-definition",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			require("templ-goto-definition").setup()
		end,
	},
	{
		"vim-dotenv",
		for_cat = "general.editor",
		cmd = { "Dotenv" },
	},
	{
		"tiny-code-actions",
		for_cat = "general.editor",
		keys = {
			{ "<leader>ca", mode = { "n", "v" }, desc = "code actions" },
		},
		after = function(plugin)
			vim.keymap.set({ "n", "v" }, "<leader>ca", function()
				require("tiny-code-action").code_action()
			end, { noremap = true, silent = true })
		end,
	},
	{
		"inline-edit",
		for_cat = "general.editor",
		keys = {
			{ "<leader>rE", mode = { "n", "v" }, desc = "Inline edit" },
		},
		after = function(plugin)
			vim.keymap.set({ "n", "v" }, "<leader>rE", "<cmd>InlineEdit<cr>", { noremap = true, silent = true })
		end,
	},
	{
		"warp-nvim",
		for_cat = "general.editor",
		keys = {
			{ "<leader>ha", mode = { "n" }, desc = "Add file to warp" },
			{ "<leader>he", mode = { "n" }, desc = "Show warp list" },
			{ "<leader>hd", mode = { "n" }, desc = "Remove file from warp" },
			{ "<leader>1", mode = { "n" }, desc = "Go to warp file 1" },
			{ "<leader>2", mode = { "n" }, desc = "Go to warp file 2" },
			{ "<leader>3", mode = { "n" }, desc = "Go to warp file 3" },
			{ "<leader>4", mode = { "n" }, desc = "Go to warp file 4" },
			{ "<leader>hn", mode = { "n" }, desc = "Next warp file" },
			{ "<leader>hp", mode = { "n" }, desc = "Prev warp file" },
		},
		after = function(plugin)
			require("warp").setup({
				auto_prune = true,
			})

			vim.keymap.set("n", "<leader>ha", "<cmd>WarpAddFile<cr>", { desc = "Add file to warp" })
			vim.keymap.set("n", "<leader>he", "<cmd>WarpShowList<cr>", { desc = "Show warp list" })
			vim.keymap.set("n", "<leader>hd", "<cmd>WarpDelFile<cr>", { desc = "Remove file from warp" })
			vim.keymap.set("n", "<leader>1", "<cmd>WarpGoToIndex 1<cr>", { desc = "Go to warp file 1" })
			vim.keymap.set("n", "<leader>2", "<cmd>WarpGoToIndex 2<cr>", { desc = "Go to warp file 2" })
			vim.keymap.set("n", "<leader>3", "<cmd>WarpGoToIndex 3<cr>", { desc = "Go to warp file 3" })
			vim.keymap.set("n", "<leader>4", "<cmd>WarpGoToIndex 4<cr>", { desc = "Go to warp file 4" })
			vim.keymap.set("n", "<leader>hn", "<cmd>WarpGoToIndex next<cr>", { desc = "Next warp file" })
			vim.keymap.set("n", "<leader>hp", "<cmd>WarpGoToIndex prev<cr>", { desc = "Prev warp file" })
		end,
	},
}
