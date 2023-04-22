local colors = require('nvimpire').colors

local signs = {
  error = "",
  warn = "",
  hint = "",
  info = "",
}

local Diagnostics = {
  static = {
    -- error_icon = vim.fn.sign_getdefined("DiagnosticSignError")[1].text,
    -- warn_icon = vim.fn.sign_getdefined("DiagnosticSignWarn")[1].text,
    -- info_icon = vim.fn.sign_getdefined("DiagnosticSignInfo")[1].text,
    -- hint_icon = vim.fn.sign_getdefined("DiagnosticSignHint")[1].text,

    error_icon = signs.error,
    warn_icon = signs.warn,
    info_icon = signs.hint,
    hint_icon = signs.info,
  },

  {
    provider = function(self)
      -- 0 is just another output, we can decide to print it or not!
      return self.errors > 0 and (self.error_icon .. self.errors .. " ")
    end,
    hl = { fg = colors.red },
  },

  {
    provider = function(self)
      -- 0 is just another output, we can decide to print it or not!
      return self.warnings > 0 and (self.warn_icon .. self.warnings .. " ")
    end,
    hl = { fg = colors.orange },
  },

  {
    provider = function(self)
      -- 0 is just another output, we can decide to print it or not!
      return self.hints > 0 and (self.hint_icon .. self.hints .. " ")
    end,
    hl = { fg = colors.cyan },
  },

  {
    provider = function(self)
      -- 0 is just another output, we can decide to print it or not!
      return self.info > 0 and (self.info_icon .. self.info .. " ")
    end,
    hl = { fg = colors.green },
  },
}

return Diagnostics
