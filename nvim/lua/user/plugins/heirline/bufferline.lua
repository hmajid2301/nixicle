local utils = require('heirline.utils')
local colors = require('nvimpire.colors').colors
local helpers = require('user.plugins.heirline.helpers')

local Left = {
  condition = function(self)
    return self.is_active
  end,
  provider = helpers.LeftBubbleChar,
  hl = function(self)
    return {
      bg = self.none,
      fg = self.bg,
    }
  end
}

local Right = {
  condition = function(self)
    return self.is_active
  end,
  provider = helpers.RightBubbleChar,
  hl = function(self)
    return {
      bg = self.none,
      fg = self.bg,
    }
  end
}

local FileTag = {
  init = function(self)
    self.modified = vim.api.nvim_buf_get_option(self.bufnr, "modified") or false
  end,
  provider = function(self)
    return self.modified and ' ' or ' '
  end
}

local FileIcon = {
  init = function(self)
    local filename = self.filename
    local extension = vim.fn.fnamemodify(filename, ":e")
    self.icon, self.icon_color = require('nvim-web-devicons').get_icon_color(filename, extension, { default = true })
  end,
  provider = function(self)
    return self.icon and (self.icon .. " ")
  end,
}

local FileName = {
  provider = function(self)
    local filename = vim.fn.fnamemodify(self.filename, ":t")
    if filename == "" then return "[No name]" end

    local diagnostic_count = 0
    -- local diagnostic_count = self.warnings + self.errors
    if self.errors > 0 then
      diagnostic_count = self.errors
    elseif self.warnings > 0 then
      diagnostic_count = self.warnings
    end

    if diagnostic_count > 0 then
      filename = filename .. " " .. tostring(diagnostic_count)
    end

    return filename
  end
}

local FilenameBlock = {
  init = function(self)
    self.filename = vim.api.nvim_buf_get_name(self.bufnr)

    local bg = self.is_active and colors.comment or colors.bg_dark
    local fg = self.is_active and colors.bg_dark or colors.comment

    -- self.git_highlight = false
    -- if conditions.is_git_repo() then
    --   ---@diagnostic disable-next-line: undefined-field
    --   local added = (vim.b.gitsigns_status_dict.added or 0) ~= 0
    --   ---@diagnostic disable-next-line: undefined-field
    --   local changed = (vim.b.gitsigns_status_dict.changed or 0) ~= 0
    --   ---@diagnostic disable-next-line: undefined-field
    --   local removed = (vim.b.gitsigns_status_dict.removed or 0) ~= 0
    --
    --   self.git_highlight = added or changed or removed
    -- end
    -- if self.git_highlight then
    --   bg = self.is_active and colors.cyan or bg
    --   fg = self.is_active and colors.bg or colors.cyan
    -- end

    self.errors = #vim.diagnostic.get(self.bufnr, { severity = vim.diagnostic.severity.ERROR }) or 0
    self.warnings = #vim.diagnostic.get(self.bufnr, { severity = vim.diagnostic.severity.WARN }) or 0

    if self.errors > 0 then
      bg = self.is_active and colors.red or bg
      fg = self.is_active and colors.bg or colors.red
    elseif self.warnings > 0 then
      bg = self.is_active and colors.orange or bg
      fg = self.is_active and colors.bg or colors.orange
    end

    self.bg = bg
    self.fg = fg
  end,
  Left,
  {
    hl = function(self)
      return {
        fg = self.fg,
        bg = self.bg,
        bold = true
      }
    end,
    FileIcon,
    FileName,
    FileTag,
  },
  Right,
  helpers.Space(2)
}

local Bufferline = utils.make_buflist(
  FilenameBlock
)

return {
  helpers.LeftBubbleSeperator(colors.bg_dark, colors.none),
  Bufferline,
  helpers.Align,
  helpers.RightBubbleSeperator(colors.bg_dark, colors.none),
}
