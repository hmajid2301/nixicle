local helpers = require('user.plugins.heirline.helpers')
local colors = require('nvimpire').colors

local ScrollBar = {
  static = {
    sbar = { '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█' }
    -- Another variant, because the more choice the better.
    -- sbar = { '🭶', '🭷', '🭸', '🭹', '🭺', '🭻' }
  },
  hl = {
    bg = colors.bg_light,
    fg = colors.pink,
  },
  provider = function(self)
    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_line_count(0)
    local i = math.floor((curr_line - 1) / lines * #self.sbar) + 1
    return string.format("%s %s", "%l:%2c %p%%", string.rep(self.sbar[i], 2))
  end,
}

return {
  helpers.LeftBubbleSeperator(colors.bg_light, colors.bg_lighter),
  helpers.Space(2),
  hl = {
    bg = colors.bg_light,
  },
  ScrollBar,
  helpers.Space(2),
}
