return {
	{
		"gitsigns.nvim",
		for_cat = "general.git",
		event = "DeferredUIEnter",
		-- cmd = { "" },
		-- ft = "",
		-- keys = "",
		-- colorscheme = "",
		after = function(plugin)
			require("gitsigns").setup({
				signs = {
					add = { text = "│" },
					change = { text = "│" },
					delete = { text = "󰍵" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
					untracked = { text = "│" },
				},
				on_attach = function(bufnr)
					local gs = package.loaded.gitsigns

					local function map(mode, l, r, opts)
						opts = opts or {}
						opts.buffer = bufnr
						vim.keymap.set(mode, l, r, opts)
					end

					map({ "n", "v" }, "]c", function()
						if vim.wo.diff then
							return "]c"
						end
						vim.schedule(function()
							gs.next_hunk()
						end)
						return "<Ignore>"
					end, { expr = true, desc = "Jump to next hunk" })

					map({ "n", "v" }, "[c", function()
						if vim.wo.diff then
							return "[c"
						end
						vim.schedule(function()
							gs.prev_hunk()
						end)
						return "<Ignore>"
					end, { expr = true, desc = "Jump to previous hunk" })

					-- Actions
					-- visual mode
					map("v", "<leader>hs", function()
						gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, { desc = "stage git hunk" })
					map("v", "<leader>hr", function()
						gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, { desc = "reset git hunk" })
					-- normal mode
					-- map("n", "<leader>gs", gs.stage_hunk, { desc = "git stage hunk" })
					-- map("n", "<leader>gr", gs.reset_hunk, { desc = "git reset hunk" })
					-- map("n", "<leader>gS", gs.stage_buffer, { desc = "git Stage buffer" })
					-- map("n", "<leader>gu", gs.undo_stage_hunk, { desc = "undo stage hunk" })
					-- map("n", "<leader>gR", gs.reset_buffer, { desc = "git Reset buffer" })
					map("n", "<leader>gp", gs.preview_hunk, { desc = "preview git hunk" })
					map("n", "<leader>gb", function()
						gs.blame_line({ full = false })
					end, { desc = "git blame line" })

					-- Toggles
					map("n", "<leader>gtb", gs.toggle_current_line_blame, { desc = "toggle git blame line" })
					map("n", "<leader>gtd", gs.toggle_deleted, { desc = "toggle git show deleted" })

					-- Text object
					map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "select git hunk" })
				end,
			})
		end,
	},
	{
		"diffview.nvim",
		for_cat = "general.git",
		event = "DeferredUIEnter",
		-- cmd = { "" },
		-- ft = "",
		-- keys = "",
		-- colorscheme = "",
		after = function(plugin)
			local actions = require("diffview.actions")

			require("diffview").setup({
				diff_binaries = false,
				enhanced_diff_hl = true, -- Enhanced diff highlighting for cleaner visuals
				use_icons = true,
				-- Better diff colors for Catppuccin
				signs = {
					fold_closed = "",
					fold_open = "",
					done = "✓",
				},
				git_cmd = { "git" },
				use_icons = true, -- Requires nvim-web-devicons
				show_help_hints = true,
				watch_index = true,

				-- Enhanced icons using Nerd Font icons
				icons = {
					folder_closed = "",
					folder_open = "",
				},

				-- Better visual signs
				signs = {
					fold_closed = "",
					fold_open = "",
					done = "✓",
				},

				-- Configure layouts for different view types
				view = {
					default = {
						layout = "diff2_horizontal",
						disable_diagnostics = true,
						winbar_info = true,
					},
					merge_tool = {
						layout = "diff3_horizontal",
						disable_diagnostics = true,
					},
				},

				-- Enhanced file panel styling
				file_panel = {
					listing_style = "tree", -- Tree view for better navigation
					tree_options = {
						flatten_dirs = true, -- Flatten single-child directories
						folder_statuses = "only_folded", -- Show status only for folded dirs
					},
					win_config = {
						position = "left",
						width = 40, -- Slightly wider for better readability
						win_opts = {},
					},
				},

				-- File history panel configuration
				file_history_panel = {
					log_options = {
						git = {
							single_file = {
								diff_merges = "combined",
							},
							multi_file = {
								diff_merges = "first-parent",
							},
						},
					},
					win_config = {
						position = "bottom",
						height = 16,
						win_opts = {},
					},
				},

				-- Default arguments for improved experience
				default_args = {
					DiffviewOpen = {},
					DiffviewFileHistory = {},
				},

				-- Hooks for enhanced visual presentation
				hooks = {
					diff_buf_read = function(bufnr)
						-- Customize diff buffer appearance
						vim.opt_local.wrap = false
						vim.opt_local.list = false
						vim.opt_local.colorcolumn = ""
						vim.opt_local.number = false
						vim.opt_local.relativenumber = false

						-- Enhanced diff colors for Catppuccin
						vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#a6e3a1", fg = "#11111b", bold = true })
						vim.api.nvim_set_hl(0, "DiffChange", { bg = "#89b4fa", fg = "#11111b", bold = true })
						vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#f38ba8", fg = "#11111b", bold = true })
						vim.api.nvim_set_hl(0, "DiffText", { bg = "#cba6f7", fg = "#11111b", bold = true })
					end,
					view_opened = function(view)
						-- Custom actions when view opens
						print(("Opened %s"):format(view.class:name()))
					end,
				},

				-- Enhanced keymaps
				keymaps = {
					view = {
						{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
						{ "n", "<leader>e", actions.focus_files, { desc = "Focus file panel" } },
						{ "n", "<leader>b", actions.toggle_files, { desc = "Toggle file panel" } },
						{ "n", "gf", actions.goto_file_edit, { desc = "Open file in new tab" } },
						{ "n", "<C-w><C-f>", actions.goto_file_split, { desc = "Open file in split" } },
						{ "n", "<C-w>gf", actions.goto_file_tab, { desc = "Open file in tab" } },
						{ "n", "<leader>co", actions.conflict_choose("ours"), { desc = "Choose ours" } },
						{ "n", "<leader>ct", actions.conflict_choose("theirs"), { desc = "Choose theirs" } },
						{ "n", "<leader>cb", actions.conflict_choose("base"), { desc = "Choose base" } },
						{ "n", "<leader>ca", actions.conflict_choose("all"), { desc = "Choose all" } },
						{ "n", "dx", actions.conflict_choose("none"), { desc = "Delete conflict region" } },
						{ "n", "]x", actions.next_conflict, { desc = "Next conflict" } },
						{ "n", "[x", actions.prev_conflict, { desc = "Previous conflict" } },
					},
					file_panel = {
						{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
						{ "n", "h", actions.close_fold, { desc = "Close fold" } },
						{ "n", "l", actions.select_entry, { desc = "Select entry" } },
						{ "n", "o", actions.select_entry, { desc = "Open entry" } },
						{ "n", "<cr>", actions.select_entry, { desc = "Open entry" } },
						{ "n", "R", actions.refresh_files, { desc = "Refresh files" } },
						{ "n", "s", actions.toggle_stage_entry, { desc = "Stage/unstage entry" } },
						{ "n", "S", actions.stage_all, { desc = "Stage all entries" } },
						{ "n", "U", actions.unstage_all, { desc = "Unstage all entries" } },
						{ "n", "X", actions.restore_entry, { desc = "Restore entry" } },
						{ "n", "L", actions.open_commit_log, { desc = "Open commit log" } },
						{ "n", "zo", actions.open_fold, { desc = "Open fold" } },
						{ "n", "zc", actions.close_fold, { desc = "Close fold" } },
						{ "n", "za", actions.toggle_fold, { desc = "Toggle fold" } },
						{ "n", "zR", actions.open_all_folds, { desc = "Open all folds" } },
						{ "n", "zM", actions.close_all_folds, { desc = "Close all folds" } },
					},
					file_history_panel = {
						{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
						{ "n", "o", actions.select_entry, { desc = "Open entry" } },
						{ "n", "<cr>", actions.select_entry, { desc = "Open entry" } },
						{ "n", "y", actions.copy_hash, { desc = "Copy commit hash" } },
						{ "n", "L", actions.open_commit_log, { desc = "Show commit details" } },
						{ "n", "zR", actions.open_all_folds, { desc = "Open all folds" } },
						{ "n", "zM", actions.close_all_folds, { desc = "Close all folds" } },
					},
					option_panel = {
						{ "n", "q", actions.close, { desc = "Close panel" } },
						{ "n", "o", actions.select_entry, { desc = "Select entry" } },
						{ "n", "<cr>", actions.select_entry, { desc = "Select entry" } },
					},
				},
			})
		end,
	},
	{
		"neogit",
		for_cat = "general.git",
		event = "DeferredUIEnter",
		-- ft = "",
		-- keys = "",
		-- colorscheme = "",
		after = function(plugin)
			require("neogit").setup()
		end,
	},
	{
		"webify-nvim",
		for_cat = "general.git",
		cmd = { "OpenFileInRepo", "OpenLineInRepo", "YankFileUrl" },
		load = function(name)
			vim.cmd.packadd(name)
		end,
	},
	{
		"git-worktree.nvim",
		for_cat = "general.git",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			-- git-worktree.nvim v2+ does not require setup()
			-- Configure using hooks if needed
			local ok, Hooks = pcall(require, "git-worktree.hooks")
			if ok then
				local update_on_switch = Hooks.builtins.update_current_buffer_on_switch

				Hooks.register(Hooks.type.SWITCH, function(path, prev_path)
					update_on_switch(path, prev_path)
				end)

				Hooks.register(Hooks.type.DELETE, function()
					vim.cmd("e .")
				end)
			end
		end,
	},
}
