return {
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
    "aserowy/tmux.nvim",
    opts = {},
    event = "User AstroFile"
  },
  {
    "olimorris/persisted.nvim",
    event = "VimEnter",
    priority = 500,
    opts = {
      use_git_branch = true,
      follow_cwd = true,
      autoload = true,
      allowed_dirs = {
        "~/.dotfiles",
        "~/work",
        "~/projects",
      },
      on_autoload_no_session = function()
        require("alpha").start(true)
      end,
    }
  },
  {
    "ray-x/go.nvim",
    dependencies = { -- optional packages
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("go").setup()
    end,
    event = { "CmdlineEnter" },
    ft = { "go", 'gomod' },
    build = ':lua require("go.install").update_all_sync()' -- if you need to install/update all binaries
  },
  {
    "nvim-neotest/neotest",
    dependencies = { -- optional packages
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-neotest/neotest-go",
      "nvim-neotest/neotest-python",
      "marilari88/neotest-vitest",
    },
    opts = {},
  },
  {
    "Pocco81/auto-save.nvim",
    opts = {},
  },
}
