return {
	{
		"dropbar.nvim",
		event = "DeferredUIEnter",
		for_cat = "ui",
		load = function(name)
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			require("dropbar").setup({
				bar = {
					enable = function(buf, win)
						return vim.fn.win_gettype(win) == ""
							and vim.wo[win].winbar == ""
							and vim.bo[buf].buftype == ""
							and (vim.bo[buf].filetype ~= "")
					end,
				},
			})
			vim.keymap.set("n", "<leader>nb", function()
				require("dropbar.api").pick()
			end, { desc = "Show dropbar picker" })
		end,
	},
	{
		"indent-blankline.nvim",
		for_cat = "ui",
		event = "DeferredUIEnter",
		after = function(plugin)
			require("ibl").setup({
				indent = {
					char = "▎",
					tab_char = "▎",
				},
				scope = {
					show_start = false,
					show_end = false,
				},
				exclude = {
					filetypes = {
						"help",
						"lspinfo",
						"TelescopePrompt",
						"TelescopeResults",
						"Trouble",
						"nvdash",
						"trouble",
					},
				},
			})
		end,
	},
	{
		"lualine.nvim",
		for_cat = "ui",
		event = "DeferredUIEnter",
		after = function(plugin)
			local theme = "catppuccin"

			vim.tbl_flatten = function(t)
				return vim.iter(t):flatten(math.huge):totable()
			end

			vim.keymap.set("n", "<leader>tq", "<cmd>tabclose<CR>", { desc = "Close tab" })

			local function show_tabline()
				return #vim.api.nvim_list_tabpages() >= 2
			end

			require("lualine").setup({
				options = {
					globalstatus = true,
					icons_enabled = true,
					theme = theme,
					section_separators = {
						right = "█",
						left = "█",
					},
					component_separators = {
						left = "",
						right = "",
					},
				},
				tabline = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = {},
					lualine_x = {},
					lualine_y = {},
					lualine_z = {
						{
							"tabs",
							cond = show_tabline,
						},
					},
				},
				sections = {
				},
			})

			vim.api.nvim_create_autocmd("TabNew", {
				callback = function()
					vim.o.showtabline = #vim.api.nvim_list_tabpages() >= 2 and 2 or 0
				end,
			})
			vim.api.nvim_create_autocmd("TabClosed", {
				callback = function()
					vim.o.showtabline = #vim.api.nvim_list_tabpages() >= 2 and 2 or 0
				end,
			})
			vim.o.showtabline = #vim.api.nvim_list_tabpages() >= 2 and 2 or 0
		end,
	},
}