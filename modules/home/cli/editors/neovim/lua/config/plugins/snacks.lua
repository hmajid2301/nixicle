return {
	{
		"snacks.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		after = function(plugin)
			require("snacks").setup({
				bigfile = { enabled = true },
				gitbrowse = { enabled = true },
				gh = { enabled = true },
				rename = { enabled = true },
				image = { enabled = true },
				quickfile = { enabled = true },
				scratch = {
					enabled = true,
					-- NvChad-style borderless theming
					win = {
						border = "single",
						title_pos = "center",
						style = "scratch",
						backdrop = 60,
					},
					icon = "   ",
					icon_hl = "SnacksScratchIcon",
					-- Scratch-specific options
					name = "Scratch",
					ft = "markdown",
					filekey = {
						cwd = true,
						branch = true,
						count = true,
					},
					root = vim.fn.stdpath("data") .. "/scratch",
				},
				styles = {
					input = {
						border = "single",
						title_pos = "center",
						backdrop = 60,
					},
					notification = {
						border = "single",
						wo = {
							winblend = 0,
							wrap = false,
						},
					},
					scratch = {
						border = "single",
						title_pos = "center",
						backdrop = 60,
						relative = "editor",
						height = 0.8,
						width = 0.8,
						zindex = 50,
						wo = {
							winhighlight = "NormalFloat:Normal,FloatBorder:TelescopeBorder",
						},
						keys = {
							["q"] = "close",
							["<Esc>"] = "close",
						},
					},
					picker = {
						border = "single",
						title_pos = "center",
						backdrop = 60,
					},
					["picker.input"] = {
						border = "single",
						title_pos = "center",
					},
					["picker.list"] = {
						border = "single",
						title_pos = "center",
					},
					["picker.preview"] = {
						border = "single",
						title_pos = "center",
					},
				},
				input = {
					enabled = true,
					icon = "   ",
					icon_hl = "SnacksInputIcon",
					prompt_pos = "top",
					border = "single",
					-- NvChad-style theming with telescope highlight groups
					win = {
						relative = "cursor",
						row = 1,
						col = 0,
						border = "single",
						title_pos = "center",
						wo = {
							winhighlight = "NormalFloat:TelescopeNormal,FloatBorder:TelescopeBorder",
							winblend = 0,
						},
					},
					-- Input-specific keymaps
					keys = {
						i_esc = { "<esc>", { "cmp_close", "cancel" }, mode = "i" },
						i_cr = { "<cr>", "confirm", mode = "i" },
						i_tab = { "<tab>", { "cmp_select_next", "cmp" }, mode = "i" },
						i_stab = { "<s-tab>", { "cmp_select_prev", "cmp" }, mode = "i" },
						q = "cancel",
					},
				},
				picker = {
					enabled = true,
					prompt_pos = "top",
					prompt = " ",
				},
			})

			-- Scratch keymaps with NvChad-style leader bindings
			-- Use a new buffer as scratch instead of the scratch() function
			vim.keymap.set("n", "<leader>.", function()
				vim.cmd("enew")
				vim.bo.buftype = "nofile"
				vim.bo.bufhidden = "hide"
				vim.bo.swapfile = false
				vim.bo.filetype = "markdown"
			end, { desc = "New Scratch Buffer" })

			vim.keymap.set("n", "<leader>S", function()
				Snacks.scratch.select()
			end, { desc = "Select Scratch Buffer" })

			-- Custom highlight for Snacks picker to match Telescope theme
			-- Using stylix colors from Nix if available, otherwise fallback to Catppuccin Mocha
			local colors = nixCats("colors")
			local red = (colors and colors.base08) or "#F38BA8"
			local black = (colors and colors.base00) or "#1E1D2D"
			local black2 = (colors and colors.base01) or "#252434"
			local white = (colors and colors.base05) or "#D9E0EE"
			local green = (colors and colors.base0B) or "#ABE9B3"
			local blue = (colors and colors.base0D) or "#89B4FA"

			-- Snacks Picker highlights matching Telescope
			vim.api.nvim_set_hl(0, "SnacksPickerTitle", { fg = black, bg = red, bold = true })
			vim.api.nvim_set_hl(0, "FloatTitle", { fg = black, bg = red, bold = true })
			vim.api.nvim_set_hl(0, "SnacksPickerPromptIcon", { fg = red, bg = black2 })
			vim.api.nvim_set_hl(0, "SnacksPickerPromptTitle", { fg = black, bg = red, bold = true })
			vim.api.nvim_set_hl(0, "SnacksPickerPrompt", { fg = white, bg = black2 })
			vim.api.nvim_set_hl(0, "SnacksPickerPromptBorder", { fg = black2, bg = black2 })
			vim.api.nvim_set_hl(0, "SnacksPickerPreviewTitle", { fg = black, bg = green, bold = true })
			vim.api.nvim_set_hl(0, "SnacksPickerSelection", { fg = white, bg = black2 })
			vim.api.nvim_set_hl(0, "SnacksPickerMatch", { fg = blue, bold = true })
			vim.api.nvim_set_hl(0, "SnacksPickerDir", { fg = blue })

			vim.api.nvim_create_autocmd("User", {
				pattern = "OilActionsPost",
				callback = function(event)
					if event.data.actions.type == "move" then
						Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
					end
				end,
			})
		end,
	},
}
