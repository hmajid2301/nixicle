local conditions = require('heirline.conditions')
local helpers = require('user.plugins.heirline.helpers')
local colors = require('nvimpire').colors

local Cwd = {
  hl = {
    fg = colors.purple,
    bg = colors.bg_lighter,
    bold = true,
  },
  helpers.Space(2),
  {
    init = function(self)
      self.cwd = vim.fn.getcwd(0)
    end,
    provider = function(self)
      local cwd = vim.fn.fnamemodify(self.cwd, ":t")

      if not conditions.width_percent_below(#cwd, 0.25) then
        cwd = vim.fn.pathshorten(self.cwd)
      end

      return " " .. cwd
    end
  },
  helpers.Space(2),
  helpers.RightSeparator(colors.bg_lighter),
}

return Cwd
