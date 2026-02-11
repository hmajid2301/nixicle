return {
	{
		"auto-session",
		-- No event trigger - this loads immediately at startup
		after = function()
			vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

			require("auto-session").setup({
				git_use_branch_name = true,
				git_auto_restore_on_branch_change = true,
				session_lens = { load_on_setup = true },
				log_level = "error",
				auto_save = function()
					-- Don't save session when opened as git editor
					local bufname = vim.api.nvim_buf_get_name(0)
					if bufname:match("COMMIT_EDITMSG") or bufname:match("MERGE_MSG") or bufname:match("git-rebase-todo") then
						return false
					end
					return true
				end,
				post_restore_cmds = {
					function()
						-- Re-enable treesitter highlighting for all buffers after session restore
						vim.schedule(function()
							for _, buf in ipairs(vim.api.nvim_list_bufs()) do
								if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
									local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
									local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })

									-- Only process normal file buffers with a filetype
									if buftype == "" and filetype ~= "" then
										pcall(vim.treesitter.start, buf)
									end
								end
							end
						end)
					end,
				},
			})

			local timer = vim.loop.new_timer()
			timer:start(
				0,
				300000,
				vim.schedule_wrap(function()
					if vim.fn.isdirectory(".git") == 1 then
						require("auto-session").save_session()
					end
				end)
			)
		end,
	},
}
