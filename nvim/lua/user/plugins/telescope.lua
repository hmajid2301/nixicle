return {
  "nvim-telescope/telescope.nvim",
  dependencies = { -- add a new dependency to telescope that is our new plugin
    "jvgrootveld/telescope-zoxide"
  },
  opts = function(_, opts)
    return require("astronvim.utils").extend_tbl(opts, {
      extensions = {
        zoxide = {
          prompt_title = " Projects List",
        },
      },
    })
  end,
  -- the first parameter is the plugin specification
  -- the second is the table of options as set up in Lazy with the `opts` key
  config = function(...)
    -- run the core AstroNvim configuration function with the options table
    require("plugins.configs.telescope")(...)

    -- require telescope and load extensions as necessary
    local telescope = require "telescope"
    telescope.load_extension "zoxide"
  end,
}
