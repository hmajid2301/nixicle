return {
	{
		"telescope.nvim",
		for_cat = "general.telescope",
		cmd = { "Telescope", "LiveGrepGitRoot", "AdvancedGitSearch" },
		on_require = { "telescope" },
		keys = {
			{ "<leader>fh", mode = { "n" }, desc = "Find help" },
			{ "<leader>ff", mode = { "n" }, desc = "Find files" },
			{ "<leader>fa", mode = { "n" }, desc = "Find all files" },
			{ "<leader>fm", mode = { "n" }, desc = "Find keymaps" },
			{ "<leader>fs", mode = { "n" }, desc = "Find telescopes" },
			{ "<leader>fw", mode = { "n" }, desc = "Find current word" },
			{ "<leader>fg", mode = { "n" }, desc = "Find grep search" },
			{ "<leader>fd", mode = { "n" }, desc = "Find diagnostics" },
			{ "<leader>fr", mode = { "n" }, desc = "Find resume" },
			{ "<leader>f.", mode = { "n" }, desc = "Find recent files" },
			{ "<leader>fb", mode = { "n" }, desc = "Find buffer" },
			{ "<leader>fc", mode = { "n" }, desc = "Find command" },
		},
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("telescope-fzf-native.nvim")
			vim.cmd.packadd("telescope-media-files")
			vim.cmd.packadd("advanced-git-search.nvim")
			vim.cmd.packadd("telescope-ui-select.nvim")
		end,
		after = function(plugin)
			require("telescope").setup({
				defaults = {
					mappings = {
						i = { ["<c-enter>"] = "to_fuzzy_refine" },
					},
					layout_config = {
						horizontal = {
							prompt_position = "top",
							preview_width = 0.55,
							results_width = 0.8,
						},
						vertical = {
							mirror = false,
						},
						width = 0.87,
						height = 0.80,
						preview_cutoff = 120,
					},
					set_env = { COLORTERM = "truecolor" },
					prompt_prefix = "   ",
					selection_caret = "  ",
					entry_prefix = "  ",
					color_devicons = true,
					initial_mode = "insert",
					selection_strategy = "reset",
					sorting_strategy = "ascending",
					file_ignore_patterns = {
						"^node_modules/",
						"^.devenv/",
						"^.direnv/",
						"^.git/",
						"^.gitlab-ci-local/",
					},
					borderchars = {
						"─",
						"│",
						"─",
						"│",
						"╭",
						"╮",
						"╯",
						"╰",
					},
					border = {},
					layout_strategy = "horizontal",
					vimgrep_arguments = {
						"rg",
						"-L",
						"--color=never",
						"--no-heading",
						"--with-filename",
						"--line-number",
						"--column",
						"--smart-case",
						"--fixed-strings",
					},
				},
				extensions = {},
			})

			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "media_files")
			pcall(require("telescope").load_extension, "advanced_git_search")
			pcall(require("telescope").load_extension, "ui-select")
			-- require("telescope").extensions.dap.configurations()

			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Find help" })
			-- vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
			vim.keymap.set("n", "<leader>fm", builtin.keymaps, { desc = "Find keymaps" })
			vim.keymap.set("n", "<leader>fs", builtin.builtin, { desc = "Find telescopes" })
			vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "Find current word" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Find grep search" })
			vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Find diagnostics" })
			vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "Find resume" })
			vim.keymap.set("n", "<leader>f.", builtin.oldfiles, { desc = "Find recent files" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffer" })
			vim.keymap.set("n", "<leader>fc", builtin.command_history, { desc = "Find command" })
			vim.keymap.set("n", "<leader>ff", function()
				builtin.find_files({ hidden = true, follow = true })
			end, { desc = "Find all files" })
		end,
	},
}
