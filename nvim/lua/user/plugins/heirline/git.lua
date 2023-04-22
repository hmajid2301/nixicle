local conditions = require('heirline.conditions')
local helpers = require('user.plugins.heirline.helpers')
local colors = require('nvimpire').colors

local Git = {
  hl = {
    fg = colors.cyan,
    bg = colors.bg_light,
  },
  {
    helpers.Space(2),
    condition = conditions.is_git_repo,
    {
      provider = function()
        ---@diagnostic disable-next-line: undefined-field
        return " " .. vim.b.gitsigns_status_dict.head
      end
    },
    helpers.Space(1),
    {
      condition = function()
        ---@diagnostic disable-next-line: undefined-field
        return vim.b.gitsigns_status_dict.added or 0 ~= 0
      end,
      provider = function()
        ---@diagnostic disable-next-line: undefined-field
        local count = vim.b.gitsigns_status_dict.added or 0
        return count > 0 and ("  " .. count) or ""
      end,
      hl = {
        fg = colors.green,
        force = true,
      },
    },
    {
      condition = function()
        ---@diagnostic disable-next-line: undefined-field
        return vim.b.gitsigns_status_dict.changed or 0 ~= 0
      end,
      provider = function()
        ---@diagnostic disable-next-line: undefined-field
        local count = vim.b.gitsigns_status_dict.changed or 0
        return count > 0 and ("  " .. count) or ""
      end,
      hl = {
        fg = colors.orange,
        force = true,
      }
    },
    {
      condition = function()
        ---@diagnostic disable-next-line: undefined-field
        return vim.b.gitsigns_status_dict.removed or 0 ~= 0
      end,
      provider = function()
        ---@diagnostic disable-next-line: undefined-field
        local count = vim.b.gitsigns_status_dict.removed or 0
        return count > 0 and ("  " .. count) or ""
      end,
      hl = {
        fg = colors.red,
        force = true,
      }
    },
    helpers.Space(2),
    helpers.RightSeparator(colors.bg_light),
  },
}

return Git
