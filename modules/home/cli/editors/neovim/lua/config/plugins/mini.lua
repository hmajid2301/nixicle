return {
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
			require("mini.files").setup({
				windows = {
					preview = true,
					width_preview = 50,
				},
			})

			vim.keymap.set("n", "<leader>e", function()
				require("mini.files").open(vim.api.nvim_buf_get_name(0))
			end, { desc = "Toggle file explorer" })
		end,
	},
}
