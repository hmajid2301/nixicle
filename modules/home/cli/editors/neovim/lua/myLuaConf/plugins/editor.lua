vim.keymap.set({ "n", "x" }, "xq", "<cmd>cclose<cr>", { desc = "Close quicklist/loclist" })

return {
	{
		"ThePrimeagen/refactoring.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("refactoring.nvim")
		end,
		after = function(plugin)
			require("refactoring").setup()

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
	{
		"echasnovski/mini.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd("mini.nvim")
			vim.cmd.packadd(name)
		end,
		config = function() end,
		after = function(plugin)
			require("mini.surround").setup()
			require("mini.comment").setup()
			require("mini.files").setup()
			require("mini.pairs").setup()
			require("mini.trailspace").setup()
		end,
	},
	{
		"otavioschwanck/arrow.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("arrow.nvim")
		end,
		after = function(plugin)
			require("arrow").setup()
		end,
	},
	{
		"RRethy/vim-illuminate",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("vim-illuminate")
		end,
		after = function(plugin)
			require("illuminate").configure({
				delay = 200,
				under_cursor = true,
				large_file_cutoff = 2000,
			})
		end,
	},
	{
		"SmiteshP/nvim-navbuddy",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("nvim-navbuddy")
		end,
		after = function(plugin)
			require("nvim-navbuddy").setup({
				lsp = {
					auto_attach = true,
				},
			})
			vim.keymap.set("n", "<leader>nb", "<cmd>Navbuddy<cr>", { desc = "Show navbuddy" })
		end,
	},
	{
		"folke/todo-comments.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("todo-comments.nvim")
		end,
		after = function(plugin)
			require("todo-comments").setup({})
		end,
	},
	{
		"MagicDuck/grug-far.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("grug-far.nvim")
		end,
		after = function(plugin)
			require("grug-far").setup({})

			local grug = require("grug-far")

			vim.keymap.set("n", "<leader>sr", grug.open, { desc = "Replace in file" })
			vim.keymap.set("n", "<leader>sw", function()
				grug.open({ prefills = { search = vim.fn.expand("<cword>") } })
			end, { desc = "Replace current word" })
			vim.keymap.set("v", "<leader>sp", function()
				grug.with_visual_selection({ prefills = { paths = vim.fn.expand("%") } })
			end, { desc = "Replace in current buffer" })
		end,
	},
	{
		"mrjones2014/smart-splits.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("smart-splits.nvim")
		end,
		after = function(plugin)
			require("smart-splits").setup({})

			local smart_splits = require("smart-splits")

			vim.keymap.set("n", "<leader>mr", smart_splits.start_resize_mode)
			vim.keymap.set("n", "<C-h>", smart_splits.move_cursor_left)
			vim.keymap.set("n", "<C-j>", smart_splits.move_cursor_down)
			vim.keymap.set("n", "<C-k>", smart_splits.move_cursor_up)
			vim.keymap.set("n", "<C-l>", smart_splits.move_cursor_right)
			vim.keymap.set("n", "<C-\\>", smart_splits.move_cursor_previous)
			vim.keymap.set("n", "<leader><leader>h", smart_splits.swap_buf_left)
			vim.keymap.set("n", "<leader><leader>j", smart_splits.swap_buf_down)
			vim.keymap.set("n", "<leader><leader>k", smart_splits.swap_buf_up)
			vim.keymap.set("n", "<leader><leader>l", smart_splits.swap_buf_right)
		end,
	},
	{
		"gx-nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("gx.nvim")
		end,
		after = function(plugin)
			require("gx").setup({})
			vim.keymap.set({ "n", "x" }, "gx", "<cmd>Browse<cr>", { desc = "Open link in Browser" })
		end,
	},
}
