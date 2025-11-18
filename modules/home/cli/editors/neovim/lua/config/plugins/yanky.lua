return {
	{
		"yanky.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
		end,
		config = function() end,
		after = function(plugin)
			require("yanky").setup({
				highlight = { timer = 150 },
			})

			vim.keymap.set({ "n", "x" }, "<leader>p", function()
				if pcall(require, "telescope") and require("telescope").extensions.yank_history then
					require("telescope").extensions.yank_history.yank_history({})
				else
					vim.cmd([[YankyRingHistory]])
				end
			end, { desc = "Open Yank History" })
			vim.keymap.set({ "n", "x" }, "y", "<Plug>(YankyYank)")
			vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
			vim.keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
			vim.keymap.set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)")
			vim.keymap.set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)")
			vim.keymap.set({ "n", "x" }, "<leader>yp", "<Plug>(YankyPutAfterCharwise)", { desc = "Inline Paste After" })
			vim.keymap.set(
				{ "n", "x" },
				"<leader>yP",
				"<Plug>(YankyPutBeforeCharwise)",
				{ desc = "Inline Paste Before" }
			)
			vim.keymap.set("n", "<c-p>", "<Plug>(YankyPreviousEntry)")
			vim.keymap.set("n", "<c-n>", "<Plug>(YankyNextEntry)")
		end,
	},
}
