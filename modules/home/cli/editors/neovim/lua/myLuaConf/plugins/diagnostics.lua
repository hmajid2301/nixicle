return {
	{
		"folke/trouble.nvim",
		for_cat = "general.diagnostics",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("trouble.nvim")
		end,
		after = function(plugin)
			require("trouble").setup()
			local trouble = require("trouble")

			vim.keymap.set("n", "]q", function()
				if trouble.is_open() then
					trouble.next({ skip_groups = true, jump = true })
				else
					local ok, err = pcall(vim.cmd.cnext)
					if not ok then
						vim.notify(err, vim.log.levels.ERROR)
					end
				end
			end, { desc = "Next quickfix item" })

			vim.keymap.set("n", "[q", function()
				if trouble.is_open() then
					trouble.previous({ skip_groups = true, jump = true })
				else
					local ok, err = pcall(vim.cmd.cprev)
					if not ok then
						vim.notify(err, vim.log.levels.ERROR)
					end
				end
			end, { desc = "Previous quickfix item" })

			vim.keymap.set(
				"n",
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				{ desc = "Document diagnostics" }
			)
			vim.keymap.set("n", "<leader>xX", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Workplace diagnostics" })
			vim.keymap.set("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location list" })
			vim.keymap.set("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix list" })
			vim.keymap.set("n", "<leader>xt", "<cmd>TodoTrouble<cr>", { desc = "Todo (trouble)" })
			vim.keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find Todos" })
		end,
	},
}
