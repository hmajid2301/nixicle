return {
	{
		"barbecue.nvim",
		event = "DeferredUIEnter",
		for_cat = "general.ui",
		-- cmd = {  },
		-- ft = "",
		-- colorscheme = "",
		load = function(name)
			vim.cmd.packadd("nvim-web-devicons")
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			require("barbecue").setup({})
		end,
	},
	{
		"nvchad-ui",
		for_cat = "general.ui",
		-- cmd = {  },
		-- event = "",
		-- ft = "",
		-- colorscheme = "",
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("base46")
		end,
		after = function(plugin)
			require("base46").load_all_highlights()
			require("nvchad")
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		for_cat = "general.ui",
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("indent-blankline.nvim")
		end,
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
		for_cat = "general.ui",
		-- cmd = { "" },
		event = "DeferredUIEnter",
		-- ft = "",
		-- keys = "",
		-- colorscheme = "",
		after = function(plugin)
			require("lualine").setup({
				options = {
					globalstatus = true,
					icons_enabled = true,
					theme = "catppuccin",
					section_separators = {
						right = "█",
						left = "█",
					},
					component_separators = {
						left = "",
						right = "",
					},
				},
				sections = {
					lualine_a = {
						{
							"mode",
							icon = " ",
							color = { gui = "bold" },
						},
					},
					lualine_b = {
						{
							"filetype",
							icon_only = true,
							colored = true,
							padding = { left = 1, right = 0 },
						},
						{
							"filename",
							color = { fg = "#FFF" },
						},
					},
					lualine_c = {
						{
							"branch",
							padding = { left = 2, right = 0 },
							icon = "",
							colored = false,
							color = {
								gui = "bold",
								fg = "#FFF",
							},
						},
						{
							"diff",
							colored = false,
							color = {
								gui = "bold",
								fg = "#605f6f",
							},
							symbols = {
								added = " ",
								modified = " ",
								removed = " ",
							},
						},
					},
					lualine_x = {
						{
							"diagnostics",
							color = {
								fg = "#605f6f",
								gui = "bold",
							},
							diagnostics_color = {
								error = { fg = "#F38BA8" },
								warn = { fg = "#FAE3B0" },
							},
							symbols = {
								error = " ",
								warn = " ",
							},
						},
						{
							function()
								return (vim.t.maximized and " ") or ""
							end,
							color = {
								fg = "#FFF",
								bg = "#CBA6F7",
								gui = "bold",
							},
						},
					},
					lualine_y = {
						{
							function()
								local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
								local clients = vim.lsp.get_active_clients()
								if next(clients) == nil then
									return "None"
								end

								local msg = ""
								for _, client in ipairs(clients) do
									local filetypes = client.config.filetypes
									if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
										msg = msg .. client.name .. " "
									end
								end

								if msg ~= "" then
									return msg
								else
									return "None"
								end
							end,
							icon = {
								" ",
								color = {
									fg = "#FFF",
									bg = "#8bc2f0",
								},
							},
							separator = {
								left = "",
							},
							padding = { left = 0, right = 0 },
							color = {
								bg = "#2d2c3c",
								fg = "#FFF",
							},
						},
						{
							"location",
							icon = {
								" ",
								color = {
									fg = "#FFF",
									bg = "#F38BA8",
								},
							},
							separator = {
								left = "",
							},
							padding = { left = 0, right = 1 },
							color = {
								bg = "#2d2c3c",
								fg = "#FFF",
							},
						},
					},
					lualine_z = {
						{
							"progress",
							icon = {
								" ",
								color = {
									fg = "#2d2c3c",
									bg = "#ABE9B3",
								},
							},
							separator = {
								left = "",
							},
							padding = { left = 0, right = 0 },
							color = {
								bg = "#2d2c3c",
								fg = "#ABE9B3",
							},
						},
					},
				},
			})
		end,
	},
	{
		"fidget.nvim",
		for_cat = "general.extra",
		event = "DeferredUIEnter",
		-- keys = "",
		after = function(plugin)
			require("fidget").setup({})
		end,
	},
	{
		"helpview.nvim",
		for_cat = "general.ui",
		event = "DeferredUIEnter",
		after = function(plugin)
			require("helpview").setup({})
		end,
	},
}
