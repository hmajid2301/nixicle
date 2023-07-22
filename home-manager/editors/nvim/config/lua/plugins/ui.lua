return {

	-- bufferline
	-- TODO: fix this
	-- {
	--   "akinsho/bufferline.nvim",
	--   event = "VeryLazy",
	--   keys = {
	--     { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle pin" },
	--     { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete non-pinned buffers" },
	--   },
	--   dependencies = { "catppuccin" },
	--   config = function()
	--     require("bufferline").setup({
	--       highlights = require("catppuccin.groups.integrations.bufferline").get(),
	--     })
	--   end,
	--   opts = {
	--     options = {
	--     -- stylua: ignore
	--     close_command = function(n) require("mini.bufremove").delete(n, false) end,
	--     -- stylua: ignore
	--     right_mouse_command = function(n) require("mini.bufremove").delete(n, false) end,
	--       diagnostics = "nvim_lsp",
	--       always_show_bufferline = false,
	--       diagnostics_indicator = function(_, _, diag)
	--         local icons = require("lazyvim.config").icons.diagnostics
	--         local ret = (diag.error and icons.Error .. diag.error .. " " or "")
	--           .. (diag.warning and icons.Warn .. diag.warning or "")
	--         return vim.trim(ret)
	--       end,
	--       offsets = {
	--         {
	--           filetype = "neo-tree",
	--           text = "Neo-tree",
	--           highlight = "Directory",
	--           text_align = "left",
	--         },
	--       },
	--     },
	--   },
	-- },

	{
		"nvim-neo-tree/neo-tree.nvim",
		opts = {
			filesystem = {
				filtered_items = {
					visible = true,
					hide_dotfiles = false,
					hide_by_name = {
						".git",
						"node_modules",
					},
				},
			},
			default_component_configs = {
				git_status = {
					symbols = {
						untracked = "★",
						ignored = "◌",
						unstaged = "✗",
						staged = "✓",
					},
				},
			},
		},
	},

	--context(
	{
		"utilyre/barbecue.nvim",
		name = "barbecue",
		dependencies = {
			"SmiteshP/nvim-navic",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			theme = "catppuccin",
		},
	},

	-- statusline
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = function()
			local icons = require("lazyvim.config").icons
			local Util = require("lazyvim.util")

			return {
				options = {
					theme = "catppuccin",
					globalstatus = true,
					section_separators = { left = "", right = "" },
					disabled_filetypes = { statusline = { "dashboard", "alpha" } },
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch" },
					lualine_c = {
						{ "progress", separator = " ", padding = { left = 1, right = 0 } },
						{ "location", padding = { left = 0, right = 1 } },
						{
							"diagnostics",
							symbols = {
								error = icons.diagnostics.Error,
								warn = icons.diagnostics.Warn,
								info = icons.diagnostics.Info,
								hint = icons.diagnostics.Hint,
							},
						},
					},
					lualine_x = {
            -- stylua: ignore
            {
              function() return require("noice").api.status.command.get() end,
              cond = function()
                return package.loaded["noice"] and
                  require("noice").api.status.command.has()
              end,
              color = Util.fg("Statement"),
            },
            -- stylua: ignore
            {
              function() return require("noice").api.status.mode.get() end,
              cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
              color = Util.fg("Constant"),
            },
            -- stylua: ignore
            {
              function() return "  " .. require("dap").status() end,
              cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end,
              color = Util.fg("Debug"),
            },
						{
							"diff",
							symbols = {
								added = icons.git.added,
								modified = icons.git.modified,
								removed = icons.git.removed,
							},
						},
					},
					lualine_y = {
						{
							"filetype",
							separator = "",
							padding = {
								left = 1,
								right = 1,
							},
						},
					},
					lualine_z = {
						{ "filename", path = 0, symbols = { modified = "  ", readonly = "", unnamed = "" } },
					},
				},
				extensions = { "neo-tree", "lazy" },
			}
		end,
	},
}
