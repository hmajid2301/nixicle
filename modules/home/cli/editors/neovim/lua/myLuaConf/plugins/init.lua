-- TODO: lazyload this
require("auto-session").setup({
	pre_save_cmds = {
		function()
			vim.opt.winbar = nil -- Clear winbar before saving session
		end,
	},
})

require("lze").load({
	{ import = "myLuaConf.plugins.telescope" },
	{ import = "myLuaConf.plugins.treesitter" },
	{ import = "myLuaConf.plugins.completion" },
	{ import = "myLuaConf.plugins.diagnostics" },
	{ import = "myLuaConf.plugins.editor" },
	{ import = "myLuaConf.plugins.file_explorer" },
	{ import = "myLuaConf.plugins.git" },
	{ import = "myLuaConf.plugins.ai" },
	{ import = "myLuaConf.plugins.ui" },
})
