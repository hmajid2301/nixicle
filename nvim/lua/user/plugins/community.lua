return {
  -- Add the community repository of plugin specifications
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.diagnostics.trouble-nvim" },
  { import = "astrocommunity.editing-support.todo-comments-nvim" },
  { import = "astrocommunity.utility.noice-nvim" },
  { import = "astrocommunity.motion.nvim-surround" },
  { import = "astrocommunity.motion.harpoon" },
  { import = "astrocommunity.motion.leap-nvim" },
  -- example of imporing a plugin, comment out to use it or add your own
  -- available plugins can be found at https://github.com/AstroNvim/astrocommunity

  -- { import = "astrocommunity.colorscheme.catppuccin" },
  -- { import = "astrocommunity.completion.copilot-lua-cmp" },
  -- { import = "astrocommunity.bars-and-lines.lualine-nvim" },
  -- {
  --   "nvim-lualine/lualine.nvim",
  --   opts = {
  --     options = {
  --       theme = bubbles_theme,
  --       component_separators = '|',
  --       section_separators = { left = '', right = '' },
  --     },
  --     sections = {
  --       lualine_a = {
  --         { 'mode', separator = { right = '' }, right_padding = 2 },
  --       },
  --       lualine_b = { 'filename', 'branch' },
  --       lualine_c = { 'fileformat' },
  --       lualine_x = {},
  --       lualine_y = { 'filetype', 'progress' },
  --       lualine_z = {
  --         { 'location', separator = { right = '' }, left_padding = 2 },
  --       },
  --     },
  --     inactive_sections = {
  --       lualine_a = { 'filename' },
  --       lualine_b = {},
  --       lualine_c = {},
  --       lualine_x = {},
  --       lualine_y = {},
  --       lualine_z = { 'location' },
  --     },
  --     tabline = {},
  --     extensions = {},
  --   }
  -- }
}
