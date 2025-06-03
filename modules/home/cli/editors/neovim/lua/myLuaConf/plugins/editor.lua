vim.keymap.set({ "n", "x" }, "xq", "<cmd>cclose<cr>", { desc = "Close quicklist/loclist" })

return {
	{
		"refactoring.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
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
		"yanky.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
		end,
		config = function() end,
		after = function(plugin)
			require("yanky").setup({
				highlight = { timer = 150 },
			})

			vim.keymap.set({ "n", "x" }, "<leader>p", function()
				if pcall(require, "telescope") and require("telescope").extensions.yank_history then
					require("telescope").extensions.yank_history.yank_history({})
				else
					vim.cmd([[YankyRingHistory]])
				end
			end, { desc = "Open Yank History" })
			vim.keymap.set({ "n", "x" }, "y", "<Plug>(YankyYank)")
			vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
			vim.keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
			vim.keymap.set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)")
			vim.keymap.set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)")
			vim.keymap.set({ "n", "x" }, "<leader>ip", "<Plug>(YankyPutAfterCharwise)", { desc = "Inline Paste After" })
			vim.keymap.set(
				{ "n", "x" },
				"<leader>iP",
				"<Plug>(YankyPutBeforeCharwise)",
				{ desc = "Inline Paste Before" }
			)
			vim.keymap.set("n", "<c-p>", "<Plug>(YankyPreviousEntry)")
			vim.keymap.set("n", "<c-n>", "<Plug>(YankyNextEntry)")
		end,
	},
	{
		"mini.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
		end,
		config = function() end,
		after = function(plugin)
			require("mini.surround").setup()
			require("mini.comment").setup()
			require("mini.files").setup()
			require("mini.pairs").setup({
				-- INFO: Taken from here: https://github.com/desdic/neovim/blob/main/lua/plugins/mini-pairs.lua
				modes = { insert = true, command = false, terminal = false },

				mappings = {
					[")"] = { action = "close", pair = "()", neigh_pattern = "[^\\]." },
					["]"] = { action = "close", pair = "[]", neigh_pattern = "[^\\]." },
					["}"] = { action = "close", pair = "{}", neigh_pattern = "[^\\]." },
					["["] = {
						action = "open",
						pair = "[]",
						neigh_pattern = ".[%s%z%)}%]]",
						register = { cr = false },
						-- foo|bar -> press "[" -> foo[bar
						-- foobar| -> press "[" -> foobar[]
						-- |foobar -> press "[" -> [foobar
						-- | foobar -> press "[" -> [] foobar
						-- foobar | -> press "[" -> foobar []
						-- {|} -> press "[" -> {[]}
						-- (|) -> press "[" -> ([])
						-- [|] -> press "[" -> [[]]
					},
					["{"] = {
						action = "open",
						pair = "{}",
						-- neigh_pattern = ".[%s%z%)}]",
						neigh_pattern = ".[%s%z%)}%]]",
						register = { cr = false },
						-- foo|bar -> press "{" -> foo{bar
						-- foobar| -> press "{" -> foobar{}
						-- |foobar -> press "{" -> {foobar
						-- | foobar -> press "{" -> {} foobar
						-- foobar | -> press "{" -> foobar {}
						-- (|) -> press "{" -> ({})
						-- {|} -> press "{" -> {{}}
					},
					["("] = {
						action = "open",
						pair = "()",
						-- neigh_pattern = ".[%s%z]",
						neigh_pattern = ".[%s%z%)]",
						register = { cr = false },
						-- foo|bar -> press "(" -> foo(bar
						-- foobar| -> press "(" -> foobar()
						-- |foobar -> press "(" -> (foobar
						-- | foobar -> press "(" -> () foobar
						-- foobar | -> press "(" -> foobar ()
					},
					-- Single quote: Prevent pairing if either side is a letter
					['"'] = {
						action = "closeopen",
						pair = '""',
						neigh_pattern = "[^%w\\][^%w]",
						register = { cr = false },
					},
					-- Single quote: Prevent pairing if either side is a letter
					["'"] = {
						action = "closeopen",
						pair = "''",
						neigh_pattern = "[^%w\\][^%w]",
						register = { cr = false },
					},
					-- Backtick: Prevent pairing if either side is a letter
					["`"] = {
						action = "closeopen",
						pair = "``",
						neigh_pattern = "[^%w\\][^%w]",
						register = { cr = false },
					},
				},
				-- -- skip autopair when next character is one of these
				skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
				-- -- skip autopair when the cursor is inside these treesitter nodes
				skip_ts = { "string" },
				-- -- skip autopair when next character is closing pair
				-- -- and there are more closing pairs than opening pairs
				skip_unbalanced = true,
				-- -- better deal with markdown code blocks
				markdown = true,
			})
			require("mini.trailspace").setup()
			vim.keymap.set("n", "<leader>e", "<cmd>lua MiniFiles.open()<CR>")
		end,
	},
	-- {
	-- 	"otavioschwanck/arrow.nvim",
	-- 	for_cat = "general.editor",
	-- 	event = "DeferredUIEnter",
	-- 	load = function(name)
	-- 		vim.cmd.packadd(name)
	-- 		vim.cmd.packadd("arrow.nvim")
	-- 	end,
	-- 	after = function(plugin)
	-- 		require("arrow").setup()
	-- 	end,
	-- },
	{
		"vim-illuminate",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			require("illuminate").configure({
				delay = 200,
				under_cursor = true,
				large_file_cutoff = 2000,
			})

			-- TODO: don't hardcode here the bg
			vim.api.nvim_set_hl(0, "IlluminatedWordText", { bg = "#383747" })
			vim.api.nvim_set_hl(0, "IlluminatedWordRead", { bg = "#383747" })
			vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { bg = "#383747" })
		end,
	},
	{
		"todo-comments.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			require("todo-comments").setup({})
		end,
	},
	{
		"grug-far.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
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
		"smart-splits.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			require("smart-splits").setup()

			local smart_splits = require("smart-splits")
			-- vim.keymap.set("n", "<leader>mr", smart_splits.start_resize_mode)
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
	{
		"inc-rename.nvim",
		for_cat = "general.editor",
		keys = {
			{ "<leader>rn", mode = { "n" }, desc = "LSP: Rename" },
		},
		cmd = { "IncRename" },
		load = function(name)
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			require("inc_rename").setup({})

			vim.keymap.set({ "n", "v" }, "<leader>rn", function()
				return ":IncRename " .. vim.fn.expand("<cword>")
			end, { expr = true })
		end,
	},
	{
		"snacks.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			require("snacks").setup({
				bigfile = { enabled = true },
				gitbrowse = { enabled = true },
				rename = { enabled = true },
				image = { enabled = true },
				quickfile = { enabled = true },
			})

			vim.api.nvim_create_autocmd("User", {
				pattern = "OilActionsPost",
				callback = function(event)
					if event.data.actions.type == "move" then
						Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
					end
				end,
			})

			vim.api.nvim_create_autocmd("User", {
				pattern = "MiniFilesActionRename",
				callback = function(event)
					Snacks.rename.on_rename_file(event.data.from, event.data.to)
				end,
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
		"undotree",
		for_cat = "general.editor",
		-- event = "DeferredUIEnter",
		keys = {
			{ "<leader>ut", mode = { "n" }, desc = " show undo tree" },
		},
		load = function(name)
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			vim.keymap.set("n", "<leader>ut", vim.cmd.UndotreeToggle, { desc = "Toggle Undotree" })
		end,
	},
	{
		"vim-dotenv",
		for_cat = "general.editor",
		cmd = { "Dotenv" },
		-- after = function(plugin)
		-- 	vim.keymap.set("n", "<leader>ut", vim.cmd.UndotreeToggle, { desc = "Toggle Undotree" })
		-- end,
	},
	{
		"tiny-code-actions",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		keys = {
			{ "<leader>ca", mode = { "n" }, desc = "code actions" },
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
		event = "DeferredUIEnter",
		keys = {
			{ "<leader>rE", mode = { "n" }, desc = "Inline edit" },
		},
		after = function(plugin)
			vim.keymap.set({ "n", "v" }, "<leader>rE", "<cmd>InlineEdit<cr>", { noremap = true, silent = true })
		end,
	},
}
