return {
	-- {
	-- 	"obsidian.nvim",
	-- 	for_cat = "general.notes",
	-- 	event = "DeferredUIEnter",
	-- 	load = function(name)
	-- 		vim.cmd.packadd(name)
	-- 	end,
	-- 	after = function(plugin)
	-- 		require("obsidian").setup({
	-- 			workspaces = {
	-- 				{
	-- 					name = "main",
	-- 					path = "~/projects/notes",
	-- 				},
	-- 			},
	--
	-- 			-- Modern command interface
	-- 			legacy_commands = false,
	--
	-- 			-- Note management
	-- 			notes_subdir = "notes",
	-- 			new_notes_location = "notes_subdir",
	--
	-- 			-- Daily notes
	-- 			daily_notes = {
	-- 				folder = "daily",
	-- 				date_format = "%Y-%m-%d",
	-- 				alias_format = "%B %-d, %Y",
	-- 				default_tags = { "daily-notes" },
	-- 			},
	--
	-- 			-- Completion settings
	-- 			completion = {
	-- 				nvim_cmp = true,
	-- 				min_chars = 2,
	-- 			},
	--
	-- 			-- Key mappings
	-- 			mappings = {
	-- 				-- Override 'gf' to work on markdown/wiki links
	-- 				["gf"] = {
	-- 					action = function()
	-- 						return require("obsidian").util.gf_passthrough()
	-- 					end,
	-- 					opts = { noremap = false, expr = true, buffer = true },
	-- 				},
	-- 				-- Toggle checkboxes
	-- 				["<leader>ch"] = {
	-- 					action = function()
	-- 						return require("obsidian").util.toggle_checkbox()
	-- 					end,
	-- 					opts = { buffer = true },
	-- 				},
	-- 				-- Smart action (follow link or toggle checkbox)
	-- 				["<cr>"] = {
	-- 					action = function()
	-- 						return require("obsidian").util.smart_action()
	-- 					end,
	-- 					opts = { buffer = true, expr = true },
	-- 				},
	-- 			},
	--
	-- 			-- Templates
	-- 			templates = {
	-- 				folder = "templates",
	-- 				date_format = "%Y-%m-%d",
	-- 				time_format = "%H:%M",
	-- 			},
	--
	-- 			-- Picker settings (you use telescope)
	-- 			picker = {
	-- 				name = "telescope.nvim",
	-- 				note_mappings = {
	-- 					new = "<C-x>",
	-- 					insert_link = "<C-l>",
	-- 				},
	-- 				tag_mappings = {
	-- 					tag_note = "<C-x>",
	-- 					insert_tag = "<C-l>",
	-- 				},
	-- 			},
	--
	-- 			-- Search settings
	-- 			sort_by = "modified",
	-- 			sort_reversed = true,
	-- 		})
	-- 	end,
	-- },
	{
		"markview.nvim",
		ft = { "markdown", "quarto", "rmd", "md" },
		after = function(plugin)
			require("markview").setup({
				preview = {
					modes = { "n", "i", "v", "V", "no", "c" },
					hybrid_modes = { "i" },
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
			})

			require("markview.extras.checkboxes").setup()
			require("markview.extras.editor").setup()
			require("markview.extras.headings").setup()
		end,
	},
}
