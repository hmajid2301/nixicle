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
				columns = {
					"icon",
					"permissions",
					"size",
					-- "mtime",
				},
				keymaps = {
					["g?"] = "actions.show_help",
					["<CR>"] = "actions.select",
					["<C-s>"] = "actions.select_vsplit",
					["<C-h>"] = "actions.select_split",
					["<C-t>"] = "actions.select_tab",
					["<C-p>"] = "actions.preview",
					["<C-c>"] = "actions.close",
					["<C-l>"] = "actions.refresh",
					["-"] = "actions.parent",
					["_"] = "actions.open_cwd",
					["`"] = "actions.cd",
					["~"] = "actions.tcd",
					["gs"] = "actions.change_sort",
					["gx"] = "actions.open_external",
					["g."] = "actions.toggle_hidden",
					["g\\"] = "actions.toggle_trash",
				},
			})
			vim.keymap.set("n", "-", "<cmd>Oil<CR>", { noremap = true, desc = "Open Parent Directory" })
			vim.keymap.set("n", "<leader>r-", "<cmd>Oil .<CR>", { noremap = true, desc = "Open nvim root directory" })
		end,
	},
}
