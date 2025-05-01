return {
	{
		"dropbar.nvim",
		event = "DeferredUIEnter",
		for_cat = "general.ui",
		-- keys = {
		-- 	{ "<leader>nb", mode = { "n" }, desc = "Show dropbar picker" },
		-- },
		load = function(name)
			vim.cmd.packadd(name)
		end,
		after = function(plugin)
			require("dropbar").setup()
			vim.keymap.set("n", "<leader>nb", function()
				require("dropbar.api").pick()
			end, { desc = "Show dropbar picker" })
		end,
	},
	{
		"tailwind-tools.nvim",
		event = "DeferredUIEnter",
		for_cat = "general.ui",
		after = function(plugin)
			require("tailwind-tools").setup({
				server = {
					override = false,
				},
				document_color = {
					enabled = true,
					kind = "inline",
					debounce = 200,
					inline_symbol = "󱓻 ",
				},
			})
		end,
	},
	{
		"indent-blankline.nvim",
		for_cat = "general.ui",
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
		for_cat = "general.ui",
		event = "DeferredUIEnter",
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
					-- tabline = {
					-- 	lualine_a = { "buffers" },
					-- 	-- if you use lualine-lsp-progress, I have mine here instead of fidget
					-- 	-- lualine_b = { 'lsp_progress', },
					-- 	lualine_z = { "tabs" },
					-- },
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
							color = { fg = "#FFFFFF" },
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
								local buf_ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
								local clients = vim.lsp.get_clients()
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

								return msg ~= "" and msg or "None"
							end,
							icon = {
								" ",
								color = {
									fg = "#2d2c3c",
									bg = "#8bc2f0",
								},
							},
							separator = {
								left = "",
								color = { fg = "#8bc2f0", bg = "#1e1e2e" },
							},
							padding = { left = 0, right = 0 },
							color = {
								bg = "#2d2c3c",
								fg = "#FFFFFF",
							},
						},
						{
							"location",
							icon = {
								" ",
								color = {
									fg = "#2d2c3c",
									bg = "#F38BA8",
								},
							},
							separator = {
								left = "",
								color = { fg = "#F38BA8", bg = "#1e1e2e" },
							},
							padding = { left = 0, right = 1 },
							color = {
								bg = "#2d2c3c",
								fg = "#FFFFFF",
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
								color = { fg = "#ABE9B3", bg = "#1e1e2e" },
							},
							padding = { left = 0, right = 0 },
							color = {
								bg = "#2d2c3c",
								fg = "#FFFFFF",
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
