return {
	{
		"mini.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
		end,
		config = function() end,
		after = function(plugin)
			require("mini.surround").setup()
			require("mini.comment").setup()
			require("mini.trailspace").setup()
			require("mini.files").setup({
				windows = {
					preview = true,
					width_preview = 50,
				},
			})

			vim.keymap.set("n", "<leader>e", function()
				require("mini.files").open(vim.api.nvim_buf_get_name(0))
			end, { desc = "Toggle file explorer" })
		end,
	},
}
