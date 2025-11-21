return {
	{
		"markview.nvim",
		ft = { "markdown", "quarto", "rmd", "md" },
		after = function(plugin)
			require("markview").setup({
				preview = {
					modes = { "n", "i", "v", "V", "no", "c" },
					hybrid_modes = { "n", "i" },
					callbacks = {
						on_attach = function(buf, wins)
							vim.api.nvim_set_option_value("conceallevel", 2, { buf = buf })
							vim.api.nvim_set_option_value("concealcursor", "", { buf = buf })
						end,
					},
				},

				markdown = {
					enable = true,
				},
				markdown_inline = {
					enable = true,
				},
				yaml = {
					properties = {
						["^id$"] = {
							use_types = false,
							text = " ",
							hl = "MarkviewIcon1",
						},
						["^title$"] = {
							use_types = false,
							text = "󰈙 ",
							hl = "MarkviewIcon1",
						},
					},
				},
			})

			require("markview.extras.checkboxes").setup()
			require("markview.extras.editor").setup()
			require("markview.extras.headings").setup()
		end,
	},
	{
		"zk-nvim",
		for_cat = "general.notes",
		cmd = { "ZkNew", "ZkNotes", "ZkTags" },
		keys = {
			{ "<leader>zn", mode = { "n" }, desc = "New note" },
			{ "<leader>zo", mode = { "n" }, desc = "Open notes" },
			{ "<leader>zt", mode = { "n" }, desc = "Search tags" },
			{ "<leader>zf", mode = { "n" }, desc = "Search notes" },
			{ "<leader>znt", mode = { "v" }, desc = "New note from title" },
			{ "<leader>znc", mode = { "v" }, desc = "New note from content" },
			{ "<leader>zi", mode = { "n" }, desc = "Insert link" },
		},
		after = function(plugin)
			require("zk").setup({
				picker = "telescope",
				lsp = {
					config = {
						cmd = { "zk", "lsp" },
						name = "zk",
					},
					auto_attach = {
						enabled = true,
						filetypes = { "markdown" },
					},
				},
			})

			local opts = { noremap = true, silent = false }

			vim.keymap.set("n", "<leader>zn", "<cmd>ZkNew { title = vim.fn.input('Title: ') }<cr>", opts)
			vim.keymap.set("n", "<leader>zo", "<cmd>ZkNotes { sort = { 'modified' } }<cr>", opts)
			vim.keymap.set("n", "<leader>zt", "<cmd>ZkTags<cr>", opts)
			vim.keymap.set(
				"n",
				"<leader>zf",
				"<cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<cr>",
				opts
			)
			vim.keymap.set("v", "<leader>znt", ":'<,'>ZkNewFromTitleSelection<cr>", opts)
			vim.keymap.set("v", "<leader>znc", ":'<,'>ZkNewFromContentSelection<cr>", opts)
			vim.keymap.set("n", "<leader>zi", "<cmd>ZkInsertLink<cr>", opts)
		end,
	},
	{
		"img-clip.nvim",
		for_cat = "general.notes",
		keys = {
			{ "<leader>ip", mode = { "n" }, desc = "Paste image from clipboard" },
		},
		after = function(plugin)
			require("img-clip").setup({
				default = {
					relative_to_current_file = true,
					prompt_for_dir_path = true,
					dir_path = "assets",
					file_name = "%Y-%m-%d-%H-%M-%S",
					prompt_for_file_name = true,
					template = "![$FILE_NAME]($FILE_PATH)",
				},
				filetypes = {
					markdown = {
						template = "![$FILE_NAME]($FILE_PATH)",
						prompt_for_dir_path = true,
						dir_path = function()
							return vim.fn.input("Directory: ", "assets/", "dir")
						end,
					},
				},
			})

			vim.keymap.set("n", "<leader>ip", "<cmd>PasteImage<cr>", { desc = "Paste image from clipboard" })
		end,
	},
}
