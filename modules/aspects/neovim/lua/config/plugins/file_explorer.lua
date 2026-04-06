return {
	{
		"oil.nvim",
		for_cat = "general.extra",
		keys = {
			{ "-", mode = { "n" }, desc = "Open parent directory" },
			{ "<leader>r-", mode = { "n" }, desc = "Open nvim root directory" },
		},
		load = function(name)
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			vim.g.loaded_netrwPlugin = 1
			require("oil").setup({
				default_file_explorer = true,
				delete_to_trash = true,
				watch_for_changes = true,
				columns = {
					"icon",
					-- "permissions",
					-- "size",
					-- "mtime",
				},
				keymaps = {
					["<C-r>"] = "actions.refresh",
				},
				view_options = {
					show_hidden = true,
				},
			})
			vim.keymap.set("n", "-", "<cmd>Oil<CR>", { noremap = true, desc = "Open Parent Directory" })
			vim.keymap.set("n", "<leader>r-", "<cmd>Oil .<CR>", { noremap = true, desc = "Open nvim root directory" })
		end,
	},
}
