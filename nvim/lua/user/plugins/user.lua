return {
  -- You can also add new plugins here as well:
  -- Add plugins, the lazy syntax
  -- "andweeb/presence.nvim",
  -- {
  --   "ray-x/lsp_signature.nvim",
  --   event = "BufRead",
  --   config = function()
  --     require("lsp_signature").setup()
  --   end,
  -- },
  {
    "Mofiqul/dracula.nvim",
    opts = function(_, opts)
      local colors = require("dracula").colors()

      opts.overrides = {
        DashboardHeader = { fg = colors.purple },
        AlphaHeaderLabel = { fg = colors.orange },
        DashboardButtons = { fg = colors.cyan },
        DashboardShortcut = { fg = colors.green },
        DashboardFooter = { fg = colors.yellow, italic = true },
      }
    end,
  },
  {
    "colevoss/nvimpire",
    opts = {},
    event = "User AstroFile"
  },
  {
    "folke/todo-comments.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    opts = {},
    event = "User AstroFile"
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    opts = {},
  },
  {
    "aserowy/tmux.nvim",
    opts = {},
    event = "User AstroFile"
  },
  {
    "folke/trouble.nvim",
    opts = {},
    event = "User AstroFile"
  },
  {
    "olimorris/persisted.nvim",
    event = "VimEnter",
    priority = 500,
    opts = {
      autoload = true
    }
  }
}
