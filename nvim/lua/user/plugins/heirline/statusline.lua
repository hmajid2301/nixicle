local colors = require('nvimpire').colors
local settings = require('nvimpire.config').settings

local Mode = require('user.heirline.mode')
local Cwd = require('user.heirline.cwd')
local Git = require('user.heirline.git')
local LspDiagnostics = require('user.heirline.lsp_diagnostics')
local helpers = require('user.heirline.helpers')

local M = {
  Mode,
  Cwd,
  Git,
  helpers.Align,
  LspDiagnostics,
  hl = {
    bg = settings.transparent and colors.none or colors.bg_dark
  }
}

return M
