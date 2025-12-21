return {
	{
		"auto-session",
		event = "VimEnter",
		config = function()
			vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

			require("auto-session").setup({
				git_use_branch_name = true,
				git_auto_restore_on_branch_change = true,
				session_lens = { load_on_setup = true },
				log_level = "error",
			})

			local timer = vim.loop.new_timer()
			timer:start(
				0,
				300000,
				vim.schedule_wrap(function()
					if vim.fn.isdirectory(".git") == 1 then
						require("auto-session").SaveSession()
					end
				end)
			)
		end,
	},
}
