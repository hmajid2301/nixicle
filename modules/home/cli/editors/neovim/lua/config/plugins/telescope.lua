return {
	{
		"telescope.nvim",
		for_cat = "general.telescope",
		cmd = { "Telescope", "LiveGrepGitRoot", "AdvancedGitSearch" },
		on_require = { "telescope" },
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("telescope-fzf-native.nvim")
			vim.cmd.packadd("telescope-media-files")
			vim.cmd.packadd("advanced-git-search.nvim")
			vim.cmd.packadd("telescope-ui-select.nvim")
			vim.cmd.packadd("git-worktree.nvim")
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
					},
				},
				extensions = {},
			})

			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "media_files")
			pcall(require("telescope").load_extension, "advanced_git_search")
			pcall(require("telescope").load_extension, "ui-select")
			pcall(require("telescope").load_extension, "git_worktree")
			-- require("telescope").extensions.dap.configurations()

			-- Git worktree keybindings
			vim.keymap.set("n", "<leader>gw", function()
				require("telescope").extensions.git_worktree.git_worktrees()
			end, { desc = "Git Worktrees (switch)" })

			vim.keymap.set("n", "<leader>gW", function()
				require("telescope").extensions.git_worktree.create_git_worktree()
			end, { desc = "Git Worktrees (create)" })
		end,
	},
}
