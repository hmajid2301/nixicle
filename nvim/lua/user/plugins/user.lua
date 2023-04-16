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
  -- {
  --   'maxmx03/dracula.nvim',
  --   lazy = false,    -- make sure we load this during startup if it is your main colorscheme
  --   priority = 1000, -- make sure to load this before all the other start plugins
  --   config = function()
  --     local dracula = require('dracula')
  --
  --     dracula.setup({})
  --   end
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
  }
}
