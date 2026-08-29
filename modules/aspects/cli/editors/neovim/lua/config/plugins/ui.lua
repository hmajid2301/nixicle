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
							mode = 2,
						},
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

