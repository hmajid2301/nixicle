return {
	{
		"snacks.nvim",
		for_cat = "general.editor",
		event = "DeferredUIEnter",
		keys = {
			{ "<leader>.", mode = { "n" }, desc = "New Scratch Buffer" },
			{ "<leader>S", mode = { "n" }, desc = "Select Scratch Buffer" },
			{ "<leader>ff", mode = { "n" }, desc = "Find files" },
			{ "<leader>fg", mode = { "n" }, desc = "Find grep" },
			{ "<leader>fb", mode = { "n" }, desc = "Find buffers" },
			{ "<leader>fh", mode = { "n" }, desc = "Find help" },
			{ "<leader>fw", mode = { "n" }, desc = "Find current word" },
			{ "<leader>f.", mode = { "n" }, desc = "Find recent files" },
			{ "<leader>fd", mode = { "n" }, desc = "Find diagnostics" },
			{ "<leader>fr", mode = { "n" }, desc = "Find resume" },
			{ "<leader>fc", mode = { "n" }, desc = "Find command history" },
			{ "<leader>fm", mode = { "n" }, desc = "Find keymaps" },
			{ "<leader>fs", mode = { "n" }, desc = "Find pickers" },
			{ "<leader>fn", mode = { "n" }, desc = "Find notes files" },
			{ "<leader>fN", mode = { "n" }, desc = "Find notes grep" },
			{ "<leader>ft", mode = { "n" }, desc = "Find latest TODOs" },
			{ "<leader>fT", mode = { "n" }, desc = "Grep latest TODOs" },
			{ "<leader>gc", mode = { "n" }, desc = "Git commits" },
			{ "<leader>gS", mode = { "n" }, desc = "Git status" },
			{ "<leader>go", mode = { "n", "v" }, desc = "Git browse (open in browser)" },
			{ "<leader>ds", mode = { "n" }, desc = "Document symbols" },
			{ "<leader>ws", mode = { "n" }, desc = "Workspace symbols" },
		},
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
					win = {
						border = "single",
						title_pos = "center",
						style = "scratch",
						backdrop = 60,
					},
					icon = "   ",
					icon_hl = "SnacksScratchIcon",
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
						title_pos = "left",
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
						title_pos = "left",
					},
					["picker.list"] = {
						border = "single",
						title_pos = "left",
					},
					["picker.preview"] = {
						border = "single",
						title_pos = "left",
					},
				},
				input = {
					enabled = true,
					icon = "   ",
					icon_hl = "SnacksInputIcon",
					border = "single",
					win = {
						relative = "cursor",
						row = 1,
						col = 0,
						border = "single",
						title_pos = "left",
						wo = {
							winhighlight = "NormalFloat:TelescopeNormal,FloatBorder:TelescopeBorder",
							winblend = 0,
						},
					},
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
					prompt = "  ",
					layout = "my_default_layout",
					win = {
						input = {
							keys = {
								["<c-f>"] = false,
							},
						},
					},
					layouts = {
						my_default_layout = {
							layout = {
								box = "vertical",
								width = 0.9,
								height = 0.9,
								border = "none",
								{
									win = "input",
									height = 1,
									border = "single",
									title = " {title} ",
									title_pos = "center",
								},
								{
									box = "horizontal",
									{
										win = "list",
										border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
									},
									{
										win = "preview",
										border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
										width = 0.6,
										title = "{preview}",
										title_pos = "center",
									},
								},
							},
						},
						my_vertical_layout = {
							layout = {
								box = "vertical",
								width = 0.8,
								height = 0.9,
								border = "none",
								{
									win = "input",
									border = "single",
									height = 1,
									title = " {title} ",
									title_pos = "center",
								},
								{
									win = "list",
									border = "none",
									height = 8,
								},
								{
									win = "preview",
									border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
									title = "{preview}",
									title_pos = "center",
								},
							},
						},
						vscode = {
							layout = {
								width = 0.5,
							},
						},
					},
					sources = {
						buffers = { layout = { preset = "my_vertical_layout" } },
						keymaps = { layout = { preset = "vscode" } },
						recent = {
							layout = { preset = "my_vertical_layout" },
							title = "Recent Files",
						},
					},
					formatters = {
						file = {
							filename_first = false,
						},
					},
				},
			})

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

			local colors = nixCats("colors")
			local red = (colors and colors.base08) or "#F38BA8"
			local black = (colors and colors.base00) or "#1E1D2D"
			local black2 = (colors and colors.base01) or "#252434"
			local white = (colors and colors.base05) or "#D9E0EE"
			local green = (colors and colors.base0B) or "#ABE9B3"
			local blue = (colors and colors.base0D) or "#89B4FA"

			vim.api.nvim_set_hl(0, "SnacksPickerTitle", { fg = black, bg = red, bold = true })
			vim.api.nvim_set_hl(0, "FloatTitle", { fg = black, bg = red, bold = true })
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

			vim.keymap.set("n", "<leader>ff", function()
				Snacks.picker.files({ hidden = true, follow = true })
			end, { desc = "Find files" })

			vim.keymap.set("n", "<leader>fg", function()
				Snacks.picker.grep({ hidden = true })
			end, { desc = "Find grep" })

			vim.keymap.set("n", "<leader>fb", function()
				Snacks.picker.buffers()
			end, { desc = "Find buffers" })

			vim.keymap.set("n", "<leader>fh", function()
				Snacks.picker.help()
			end, { desc = "Find help" })

			vim.keymap.set("n", "<leader>fw", function()
				Snacks.picker.grep_word()
			end, { desc = "Find current word" })

			vim.keymap.set("n", "<leader>f.", function()
				Snacks.picker.recent()
			end, { desc = "Find recent files" })

			vim.keymap.set("n", "<leader>fd", function()
				Snacks.picker.diagnostics()
			end, { desc = "Find diagnostics" })

			vim.keymap.set("n", "<leader>fr", function()
				Snacks.picker.resume()
			end, { desc = "Find resume" })

			vim.keymap.set("n", "<leader>fc", function()
				Snacks.picker.command_history()
			end, { desc = "Find command history" })

			vim.keymap.set("n", "<leader>fm", function()
				Snacks.picker.keymaps()
			end, { desc = "Find keymaps" })

			vim.keymap.set("n", "<leader>fs", function()
				Snacks.picker.pickers()
			end, { desc = "Find pickers" })

			local notes_dir = vim.fn.expand("~/projects/notes")
			vim.keymap.set("n", "<leader>fn", function()
				Snacks.picker.files({
					cwd = notes_dir,
					hidden = true,
					follow = true,
				})
			end, { desc = "Find notes files" })

			vim.keymap.set("n", "<leader>fN", function()
				Snacks.picker.grep({
					cwd = notes_dir,
					hidden = true,
				})
			end, { desc = "Find notes grep" })

			vim.keymap.set("n", "<leader>gc", function()
				Snacks.picker.git_log()
			end, { desc = "Git commits" })

			vim.keymap.set("n", "<leader>gS", function()
				Snacks.picker.git_status()
			end, { desc = "Git status" })

			vim.keymap.set({ "n", "v" }, "<leader>go", function()
				Snacks.gitbrowse.open()
			end, { desc = "Git browse (open in browser)" })

			vim.keymap.set("n", "<leader>ds", function()
				Snacks.picker.lsp_symbols()
			end, { desc = "Document symbols" })

			vim.keymap.set("n", "<leader>ws", function()
				Snacks.picker.lsp_workspace_symbols()
			end, { desc = "Workspace symbols" })

			-- Latest TODOs pickers
			local todos = require("config.todos")
			todos.setup() -- Create user commands

			vim.keymap.set("n", "<leader>ft", function()
				todos.search_latest_todos()
			end, { desc = "Find latest TODOs" })

			vim.keymap.set("n", "<leader>fT", function()
				todos.grep_latest_todos()
			end, { desc = "Grep latest TODOs" })
		end,
	},
}
