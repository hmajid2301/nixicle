return {
	{
		"nvim-treesitter",
		for_cat = "general.treesitter",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("nvim-treesitter-textobjects")
		end,
		after = function(plugin)
			require("nvim-treesitter").setup()

			vim.keymap.set("x", "<c-space>", function()
				vim.lsp.buf.selection_range("outer")
			end, { desc = "Expand selection (incremental)" })

			vim.keymap.set("x", "<M-space>", function()
				vim.lsp.buf.selection_range("inner")
			end, { desc = "Shrink selection (incremental)" })

			vim.keymap.set("n", "<c-space>", function()
				vim.cmd("normal! v")
				vim.lsp.buf.selection_range("outer")
			end, { desc = "Start incremental selection" })

			vim.keymap.set("x", "<c-s>", function()
				vim.lsp.buf.selection_range("outer")
			end, { desc = "Expand to scope" })
		end,
	},
	{
		"nvim-treesitter-textobjects",
		for_cat = "general.treesitter",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			require("nvim-treesitter-textobjects").setup({
				select = {
					lookahead = true,
					selection_modes = {
						["@parameter.outer"] = "v",
						["@function.outer"] = "V",
						["@class.outer"] = "<c-v>",
					},
					include_surrounding_whitespace = false,
				},
				move = {
					set_jumps = true,
				},
			})


			-- Set up select keymaps using the new API
			vim.keymap.set({ "x", "o" }, "af", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "if", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ac", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ic", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "aa", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@parameter.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ia", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@parameter.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ab", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@block.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ib", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@block.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ai", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@conditional.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ii", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@conditional.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "al", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@loop.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "il", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@loop.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "am", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@call.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "im", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@call.inner", "textobjects")
			end)
<<<<<<< HEAD

=======
			
>>>>>>> 32e4968 (work)
			-- Move keymaps using the new API
			vim.keymap.set({ "n", "x", "o" }, "]m", function()
				require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]]", function()
				require("nvim-treesitter-textobjects.move").goto_next_start("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]M", function()
				require("nvim-treesitter-textobjects.move").goto_next_end("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "][", function()
				require("nvim-treesitter-textobjects.move").goto_next_end("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[m", function()
				require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[[", function()
				require("nvim-treesitter-textobjects.move").goto_previous_start("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[M", function()
				require("nvim-treesitter-textobjects.move").goto_previous_end("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[]", function()
				require("nvim-treesitter-textobjects.move").goto_previous_end("@class.outer", "textobjects")
			end)

			-- Swap keymaps using the new API
			vim.keymap.set("n", "<leader>a", function()
				require("nvim-treesitter-textobjects.swap").swap_next("@parameter.inner")
			end)
			vim.keymap.set("n", "<leader>A", function()
				require("nvim-treesitter-textobjects.swap").swap_previous("@parameter.outer")
			end)

			-- Set up repeatable move keymaps using the correct module path
			local ts_repeat_ok, ts_repeat_move = pcall(require, "nvim-treesitter-textobjects.repeatable_move")
			if ts_repeat_ok then
				vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
				vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)
				vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
				vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
				vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
				vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })
			end
		end,
	},
}
