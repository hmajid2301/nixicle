-- TODO: lazyload this
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

require("auto-session").setup({
	pre_save_cmds = {
		function()
			vim.cmd([[
                noautocmd windo set winbar=
                noautocmd windo setlocal winbar=
            ]])
		end,
	},
})

require("lze").load({
	{ import = "config.plugins.telescope" },
	{ import = "config.plugins.treesitter" },
	{ import = "config.plugins.completion" },
	{ import = "config.plugins.diagnostics" },
	{ import = "config.plugins.editor" },
	{ import = "config.plugins.mini" },
	{ import = "config.plugins.snacks" },
	{ import = "config.plugins.yanky" },
	{ import = "config.plugins.refactoring" },
	{ import = "config.plugins.file_explorer" },
	{ import = "config.plugins.git" },
	{ import = "config.plugins.ai" },
	{ import = "config.plugins.notes" },
	{ import = "config.plugins.ui" },
})
