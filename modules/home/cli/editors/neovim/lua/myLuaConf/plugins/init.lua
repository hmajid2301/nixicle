-- TODO: lazyload this
require("auto-session").setup({
	pre_save_cmds = {
		function()
			for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
				local wins = vim.api.nvim_tabpage_list_wins(tab)
				for _, win in ipairs(wins) do
					vim.api.nvim_set_option_value("winbar", nil, { scope = "win", win = win })
				end
			end
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
