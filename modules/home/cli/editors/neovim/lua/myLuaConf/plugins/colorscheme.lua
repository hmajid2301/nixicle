local colors = {
	white = "#D9E0EE",
	darker_black = "#191828",
	black = "#1E1D2D",
	black2 = "#252434",
	one_bg = "#2d2c3c",
	one_bg2 = "#363545",
	one_bg3 = "#3e3d4d",
	grey = "#474656",
	grey_fg = "#4e4d5d",
	grey_fg2 = "#555464",
	light_grey = "#605f6f",
	red = "#F38BA8",
	maroon = "#eba0ac",
	baby_pink = "#ffa5c3",
	pink = "#F5C2E7",
	line = "#383747",
	green = "#ABE9B3",
	vibrant_green = "#b6f4be",
	nord_blue = "#8bc2f0",
	mauve = "#cba6f7",
	blue = "#89B4FA",
	yellow = "#FAE3B0",
	sun = "#ffe9b6",
	purple = "#d0a9e5",
	dark_purple = "#c7a0dc",
	teal = "#B5E8E0",
	peach = "#fab387",
	orange = "#F8BD96",
	cyan = "#89DCEB",
	sky = "#89DCEB",
	statusline_bg = "#232232",
	lightbg = "#2f2e3e",
	pmenu_bg = "#ABE9B3",
	folder_bg = "#89B4FA",
	lavender = "#c7d1ff",
	text = "#cdd6f4",
	surface2 = "#585b70",
	surface1 = "#45475a",
	surface0 = "#313244",

	base00 = "#1E1D2D",
	base01 = "#282737",
	base02 = "#2f2e3e",
	base03 = "#383747",
	base04 = "#414050",
	base05 = "#bfc6d4",
	base06 = "#ccd3e1",
	base07 = "#D9E0EE",
	base08 = "#F38BA8",
	base09 = "#F8BD96",
	base0A = "#FAE3B0",
	base0B = "#ABE9B3",
	base0C = "#89DCEB",
	base0D = "#89B4FA",
	base0E = "#CBA6F7",
	base0F = "#F38BA8",
}

local colorschemeName = nixCats("colorscheme")
if not require("nixCatsUtils").isNixCats then
	colorschemeName = "catppuccin"
end
-- Could I lazy load on colorscheme with lze?
-- sure. But I was going to call vim.cmd.colorscheme() during startup anyway
-- this is just an example, feel free to do a better job!
vim.cmd.colorscheme(colorschemeName)

require("catppuccin").setup({
	flavour = "mocha",
	color_overrides = {
		all = colors,
	},
	integrations = {
		blink_cmp = true,
		dashboard = true,
		gitsigns = true,
		illuminate = { enabled = true },
		flash = true,
		indent_blankline = { enabled = true },
		mini = { enabled = true },
		navic = { enabled = true },
		telescope = { enabled = true },
	},
})

-- DAP configuration
local sign = vim.fn.sign_define
sign("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" })
sign("DapBreakpointCondition", { text = "●", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
sign("DapLogPoint", { text = "◆", texthl = "DapLogPoint", linehl = "", numhl = "" })
sign("DapStopped", { text = "", texthl = "DapStopped", linehl = "DapStopped", numhl = "DapStopped" })

local hl = vim.api.nvim_set_hl

-- General UI
hl(0, "Normal", { fg = colors.base05, bg = colors.base00 })
hl(0, "SignColumn", { fg = colors.base03 })
hl(0, "MsgArea", { fg = colors.base05, bg = colors.base00 })
hl(0, "ModeMsg", { fg = colors.base0B })
hl(0, "MsgSeparator", { fg = colors.base05, bg = colors.base00 })
hl(0, "SpellBad", { sp = colors.base08, undercurl = true })
hl(0, "SpellCap", { sp = colors.base0D, undercurl = true })
hl(0, "SpellLocal", { sp = colors.base0C, undercurl = true })
hl(0, "SpellRare", { sp = colors.base0D, undercurl = true })
hl(0, "NormalNC", { fg = colors.base05, bg = colors.base00 })
hl(0, "Pmenu", { bg = colors.one_bg })
hl(0, "PmenuSel", { fg = colors.black, bg = colors.pmenu_bg })
hl(0, "WildMenu", { fg = colors.base08, bg = colors.base0A })
hl(0, "CursorLineNr", { fg = colors.white })
hl(0, "Comment", { fg = colors.grey_fg })
hl(0, "Folded", { fg = colors.base03, bg = colors.base01 })
hl(0, "FoldColumn", { fg = colors.base0C, bg = colors.base01 })
hl(0, "LineNr", { fg = colors.grey })
hl(0, "FloatBorder", { fg = colors.blue })
hl(0, "VertSplit", { fg = colors.line })
hl(0, "CursorLine", { bg = colors.black2 })
hl(0, "CursorColumn", { bg = colors.black2 })
hl(0, "ColorColumn", { bg = colors.black2 })
hl(0, "NormalFloat", { bg = colors.darker_black })
hl(0, "Visual", { bg = colors.base02 })
hl(0, "VisualNOS", { fg = colors.base08 })
hl(0, "WarningMsg", { fg = colors.base08 })
hl(0, "DiffAdd", { fg = colors.vibrant_green })
hl(0, "DiffChange", { fg = colors.blue })
hl(0, "DiffDelete", { fg = colors.red })
hl(0, "QuickFixLine", { bg = colors.base01 })
hl(0, "PmenuSbar", { bg = colors.one_bg })
hl(0, "PmenuThumb", { bg = colors.grey })
hl(0, "MatchWord", { fg = colors.white, bg = colors.grey })
hl(0, "MatchParen", { link = "MatchWord" })
hl(0, "Cursor", { fg = colors.base00, bg = colors.base05 })
hl(0, "Conceal", {})
hl(0, "Directory", { fg = colors.base0D })
hl(0, "SpecialKey", { fg = colors.base03 })
hl(0, "Title", { fg = colors.base0D })
hl(0, "ErrorMsg", { fg = colors.base08, bg = colors.base00 })
hl(0, "Search", { fg = colors.base01, bg = colors.base0A })
hl(0, "IncSearch", { fg = colors.base01, bg = colors.base09 })
hl(0, "Substitute", { fg = colors.base01, bg = colors.base0A })
hl(0, "MoreMsg", { fg = colors.base0B })
hl(0, "Question", { fg = colors.base0D })
hl(0, "NonText", { fg = colors.base03 })

-- Syntax
hl(0, "Variable", { fg = colors.base05 })
hl(0, "String", { fg = colors.base0B })
hl(0, "Character", { fg = colors.base08 })
hl(0, "Constant", { fg = colors.base08 })
hl(0, "Number", { fg = colors.base09 })
hl(0, "Boolean", { fg = colors.base09 })
hl(0, "Float", { fg = colors.base09 })
hl(0, "Identifier", { fg = colors.base08 })
hl(0, "Function", { fg = colors.base0D })
hl(0, "Operator", { fg = colors.base05 })
hl(0, "Type", { fg = colors.base0A })
hl(0, "StorageClass", { fg = colors.base0A })
hl(0, "Structure", { fg = colors.base0E })
hl(0, "Typedef", { fg = colors.base0A })
hl(0, "Keyword", { fg = colors.base0E })
hl(0, "Statement", { fg = colors.base08 })
hl(0, "Conditional", { fg = colors.base0E })
hl(0, "Repeat", { fg = colors.base0A })
hl(0, "Label", { fg = colors.base0A })
hl(0, "Exception", { fg = colors.base08 })
hl(0, "Include", { fg = colors.base0D })
hl(0, "PreProc", { fg = colors.base0A })
hl(0, "Define", { fg = colors.base0E })
hl(0, "Macro", { fg = colors.base08 })
hl(0, "Special", { fg = colors.base0C })
hl(0, "SpecialChar", { fg = colors.base0F })
hl(0, "Tag", { fg = colors.base0A })
hl(0, "Debug", { fg = colors.base08 })
hl(0, "Underlined", { fg = colors.base0B })
hl(0, "Bold", { bold = true })
hl(0, "Italic", { italic = true })
hl(0, "Ignore", { fg = colors.cyan, bg = colors.base00, bold = true })
hl(0, "Todo", { fg = colors.base0A, bg = colors.base01 })
hl(0, "Error", { fg = colors.base00, bg = colors.base08 })
hl(0, "TabLine", { fg = colors.light_grey, bg = colors.line })
hl(0, "TabLineSel", { fg = colors.white, bg = colors.line })
hl(0, "TabLineFill", { fg = colors.line, bg = colors.line })

-- Treesitter
hl(0, "@annotation", { fg = colors.base0F })
hl(0, "@attribute", { fg = colors.base0A })
hl(0, "@constructor", { fg = colors.base0C })
hl(0, "@type.builtin", { fg = colors.base0A })
hl(0, "@conditional", { link = "Conditional" })
hl(0, "@exception", { fg = colors.base08 })
hl(0, "@include", { link = "Include" })
hl(0, "@keyword.return", { fg = colors.base0E })
hl(0, "@keyword", { fg = colors.base0E })
hl(0, "@keyword.function", { fg = colors.base0E })
hl(0, "@namespace", { fg = colors.base08 })
hl(0, "@constant.builtin", { fg = colors.base09 })
hl(0, "@float", { fg = colors.base09 })
hl(0, "@character", { fg = colors.base08 })
hl(0, "@error", { fg = colors.base08 })
hl(0, "@function", { fg = colors.base0D })
hl(0, "@function.builtin", { fg = colors.base0D })
hl(0, "@method", { fg = colors.base0D })
hl(0, "@constant.macro", { fg = colors.base08 })
hl(0, "@function.macro", { fg = colors.base08 })
hl(0, "@variable", { fg = colors.lavender })
hl(0, "@variable.builtin", { fg = colors.red })
hl(0, "@property", { fg = colors.base08 })
hl(0, "@field", { fg = colors.base0D })
hl(0, "@parameter", { fg = colors.base08 })
hl(0, "@parameter.reference", { fg = colors.base05 })
hl(0, "@symbol", { fg = colors.base0B })
hl(0, "@text", { fg = colors.base05 })
hl(0, "@punctuation.delimiter", { fg = colors.base0F })
hl(0, "@tag.delimiter", { fg = colors.base0F })
hl(0, "@punctuation.bracket", { fg = colors.base0F })
hl(0, "@punctuation.special", { fg = colors.base08 })
hl(0, "@string.regex", { fg = colors.base0C })
hl(0, "@string.escape", { fg = colors.base0C })
hl(0, "@emphasis", { fg = colors.base09 })
hl(0, "@literal", { fg = colors.base09 })
hl(0, "@text.uri", { fg = colors.base09 })
hl(0, "@keyword.operator", { fg = colors.base0E })
hl(0, "@strong", { bold = true })
hl(0, "@scope", { bold = true })
hl(0, "TreesitterContext", { link = "CursorLine" })

-- Plugins
hl(0, "DashboardHeader", { fg = colors.blue })
hl(0, "DashboardCenter", { fg = colors.purple })
hl(0, "DashboardFooter", { fg = colors.cyan })
hl(0, "AlphaHeader", { fg = colors.blue })
hl(0, "AlphaButtons", { fg = colors.purple })
hl(0, "AlphaFooter", { fg = colors.cyan })

-- Git
hl(0, "SignAdd", { fg = colors.green })
hl(0, "SignChange", { fg = colors.blue })
hl(0, "SignDelete", { fg = colors.red })
hl(0, "GitSignsAdd", { fg = colors.green })
hl(0, "GitSignsChange", { fg = colors.blue })
hl(0, "GitSignsDelete", { fg = colors.red })

-- Diagnostics
hl(0, "DiagnosticError", { fg = colors.base08 })
hl(0, "DiagnosticWarning", { fg = colors.base09 })
hl(0, "DiagnosticHint", { fg = colors.purple })
hl(0, "DiagnosticWarn", { fg = colors.yellow })
hl(0, "DiagnosticInfo", { fg = colors.green })
hl(0, "LspDiagnosticsDefaultError", { fg = colors.base08 })
hl(0, "LspDiagnosticsDefaultWarning", { fg = colors.base09 })
hl(0, "LspDiagnosticsDefaultInformation", { fg = colors.sun })
hl(0, "LspDiagnosticsDefaultInfo", { fg = colors.sun })
hl(0, "LspDiagnosticsDefaultHint", { fg = colors.purple })
hl(0, "LspDiagnosticsVirtualTextError", { fg = colors.base08 })
hl(0, "LspDiagnosticsVirtualTextWarning", { fg = colors.base09 })
hl(0, "LspDiagnosticsVirtualTextInformation", { fg = colors.sun })
hl(0, "LspDiagnosticsVirtualTextInfo", { fg = colors.sun })
hl(0, "LspDiagnosticsVirtualTextHint", { fg = colors.purple })
hl(0, "LspDiagnosticsFloatingError", { fg = colors.base08 })
hl(0, "LspDiagnosticsFloatingWarning", { fg = colors.base09 })
hl(0, "LspDiagnosticsFloatingInformation", { fg = colors.sun })
hl(0, "LspDiagnosticsFloatingInfo", { fg = colors.sun })
hl(0, "LspDiagnosticsFloatingHint", { fg = colors.purple })
hl(0, "DiagnosticSignError", { fg = colors.base08 })
hl(0, "DiagnosticSignWarning", { fg = colors.base09 })
hl(0, "DiagnosticSignInformation", { fg = colors.sun })
hl(0, "DiagnosticSignInfo", { fg = colors.sun })
hl(0, "DiagnosticSignHint", { fg = colors.purple })
hl(0, "LspDiagnosticsSignError", { fg = colors.base08 })
hl(0, "LspDiagnosticsSignWarning", { fg = colors.base09 })
hl(0, "LspDiagnosticsSignInformation", { fg = colors.sun })
hl(0, "LspDiagnosticsSignInfo", { fg = colors.sun })
hl(0, "LspDiagnosticsSignHint", { fg = colors.purple })
hl(0, "LspDiagnosticsError", { fg = colors.base08 })
hl(0, "LspDiagnosticsWarning", { fg = colors.base09 })
hl(0, "LspDiagnosticsInformation", { fg = colors.sun })
hl(0, "LspDiagnosticsInfo", { fg = colors.sun })
hl(0, "LspDiagnosticsHint", { fg = colors.purple })
hl(0, "LspDiagnosticsUnderlineError", { underline = true })
hl(0, "LspDiagnosticsUnderlineWarning", { underline = true })
hl(0, "LspDiagnosticsUnderlineInformation", { underline = true })
hl(0, "LspDiagnosticsUnderlineInfo", { underline = true })
hl(0, "LspDiagnosticsUnderlineHint", { underline = true })
hl(0, "LspReferenceRead", { bg = "#2e303b" })
hl(0, "LspReferenceText", { bg = "#2e303b" })
hl(0, "LspReferenceWrite", { bg = "#2e303b" })
hl(0, "LspCodeLens", { fg = colors.base04, italic = true })
hl(0, "LspCodeLensSeparator", { fg = colors.base04, italic = true })

-- Telescope
hl(0, "TelescopeNormal", { bg = colors.darker_black })
hl(0, "TelescopePreviewTitle", { fg = colors.black, bg = colors.green, bold = true })
hl(0, "TelescopePromptTitle", { fg = colors.black, bg = colors.red, bold = true })
hl(0, "TelescopeResultsTitle", { fg = colors.darker_black, bg = colors.darker_black, bold = true })
hl(0, "TelescopeSelection", { fg = colors.white, bg = colors.black2 })
hl(0, "TelescopeBorder", { fg = colors.darker_black, bg = colors.darker_black })
hl(0, "TelescopePromptBorder", { fg = colors.black2, bg = colors.black2 })
hl(0, "TelescopePromptNormal", { fg = colors.white, bg = colors.black2 })
hl(0, "TelescopePromptPrefix", { fg = colors.red, bg = colors.black2 })
hl(0, "TelescopeResultsDiffAdd", { fg = colors.green })
hl(0, "TelescopeResultsDiffChange", { fg = colors.blue })
hl(0, "TelescopeResultsDiffDelete", { fg = colors.red })

-- NvimTree
hl(0, "NvimTreeFolderIcon", { fg = colors.blue })
hl(0, "NvimTreeIndentMarker", { fg = colors.grey_fg })
hl(0, "NvimTreeNormal", { bg = colors.darker_black })
hl(0, "NvimTreeVertSplit", { fg = colors.darker_black, bg = colors.darker_black })
hl(0, "NvimTreeFolderName", { fg = colors.blue })
hl(0, "NvimTreeOpenedFolderName", { fg = colors.blue, bold = true, italic = true })
hl(0, "NvimTreeEmptyFolderName", { fg = colors.grey, italic = true })
hl(0, "NvimTreeGitIgnored", { fg = colors.grey, italic = true })
hl(0, "NvimTreeImageFile", { fg = colors.light_grey })
hl(0, "NvimTreeSpecialFile", { fg = colors.orange })
hl(0, "NvimTreeEndOfBuffer", { fg = colors.darker_black })
hl(0, "NvimTreeCursorLine", { bg = "#282b37" })
hl(0, "NvimTreeGitignoreIcon", { fg = colors.red })
hl(0, "NvimTreeGitStaged", { fg = colors.vibrant_green })
hl(0, "NvimTreeGitNew", { fg = colors.vibrant_green })
hl(0, "NvimTreeGitRenamed", { fg = colors.vibrant_green })
hl(0, "NvimTreeGitDeleted", { fg = colors.red })
hl(0, "NvimTreeGitMerge", { fg = colors.blue })
hl(0, "NvimTreeGitDirty", { fg = colors.blue })
hl(0, "NvimTreeSymlink", { fg = colors.cyan })
hl(0, "NvimTreeRootFolder", { fg = colors.base05, bold = true })

-- Bufferline
hl(0, "BufferCurrent", { fg = colors.base05, bg = colors.base00 })
hl(0, "BufferCurrentIndex", { fg = colors.base05, bg = colors.base00 })
hl(0, "BufferCurrentMod", { fg = colors.sun, bg = colors.base00 })
hl(0, "BufferCurrentSign", { fg = colors.purple, bg = colors.base00 })
hl(0, "BufferCurrentTarget", { fg = colors.red, bg = colors.base00, bold = true })
hl(0, "BufferVisible", { fg = colors.base05, bg = colors.base00 })
hl(0, "BufferVisibleIndex", { fg = colors.base05, bg = colors.base00 })
hl(0, "BufferVisibleMod", { fg = colors.sun, bg = colors.base00 })
hl(0, "BufferVisibleSign", { fg = colors.grey, bg = colors.base00 })
hl(0, "BufferVisibleTarget", { fg = colors.red, bg = colors.base00, bold = true })
hl(0, "BufferInactive", { fg = colors.grey, bg = colors.darker_black })
hl(0, "BufferInactiveIndex", { fg = colors.grey, bg = colors.darker_black })
hl(0, "BufferInactiveMod", { fg = colors.sun, bg = colors.darker_black })
hl(0, "BufferInactiveSign", { fg = colors.grey, bg = colors.darker_black })
hl(0, "BufferInactiveTarget", { fg = colors.red, bg = colors.darker_black, bold = true })

-- Statusline
hl(0, "StatusLine", { fg = colors.line, bg = colors.statusline_bg })
hl(0, "StatusLineNC", { bg = colors.statusline_bg })
hl(0, "StatusLineSeparator", { fg = colors.line })
hl(0, "StatusLineTerm", { fg = colors.line })
hl(0, "StatusLineTermNC", { fg = colors.line })

-- Dashboard
hl(0, "DashboardHeader", { fg = colors.blue })
hl(0, "DashboardCenter", { fg = colors.purple })
hl(0, "DashboardFooter", { fg = colors.cyan })
hl(0, "AlphaHeader", { fg = colors.blue })
hl(0, "AlphaButtons", { fg = colors.purple })
hl(0, "AlphaFooter", { fg = colors.cyan })

-- CMP
hl(0, "CmpItemAbbr", { fg = colors.white })
hl(0, "CmpDoc", { bg = colors.darker_black })
hl(0, "CmpBorder", { fg = colors.grey_fg })
hl(0, "CmpDocBorder", { fg = colors.darker_black, bg = colors.darker_black })
hl(0, "CmpPmenu", { bg = colors.black })
hl(0, "CmpSel", { bg = colors.pmenu_bg, fg = colors.black, bold = true })
hl(0, "CmpItemAbbrDeprecated", { fg = colors.grey, strikethrough = true })
hl(0, "CmpItemAbbrMatch", { fg = colors.blue, bold = true })
hl(0, "CmpItemAbbrMatchFuzzy", { fg = colors.blue })
hl(0, "CmpItemKindFunction", { fg = colors.blue })
hl(0, "CmpItemKindMethod", { fg = colors.blue })
hl(0, "CmpItemKindConstructor", { fg = colors.cyan })
hl(0, "CmpItemKindClass", { fg = colors.cyan })
hl(0, "CmpItemKindEnum", { fg = colors.cyan })
hl(0, "CmpItemKindEvent", { fg = colors.yellow })
hl(0, "CmpItemKindInterface", { fg = colors.cyan })
hl(0, "CmpItemKindStruct", { fg = colors.cyan })
hl(0, "CmpItemKindVariable", { fg = colors.red })
hl(0, "CmpItemKindField", { fg = colors.red })
hl(0, "CmpItemKindProperty", { fg = colors.red })
hl(0, "CmpItemKindEnumMember", { fg = colors.orange })
hl(0, "CmpItemKindConstant", { fg = colors.orange })
hl(0, "CmpItemKindKeyword", { fg = colors.purple })
hl(0, "CmpItemKindModule", { fg = colors.cyan })
hl(0, "CmpItemKindValue", { fg = colors.cyan })
hl(0, "CmpItemKindUnit", { fg = colors.base0E })
hl(0, "CmpItemKindText", { fg = colors.base0B })
hl(0, "CmpItemKindSnippet", { fg = colors.yellow })
hl(0, "CmpItemKindFile", { fg = colors.base07 })
hl(0, "CmpItemKindFolder", { fg = colors.base07 })
hl(0, "CmpItemKindColor", { fg = colors.white })
hl(0, "CmpItemKindReference", { fg = colors.base05 })
hl(0, "CmpItemKindOperator", { fg = colors.base05 })
hl(0, "CmpItemKindTypeParameter", { fg = colors.base08 })

-- Blink
hl(0, "BlinkCmpMenu", { bg = colors.black })
hl(0, "BlinkCmpMenuBorder", { fg = colors.grey_fg })
hl(0, "BlinkCmpMenuSelection", { link = "PmenuSel", bold = true })
hl(0, "BlinkCmpScrollBarThumb", { bg = colors.grey })
hl(0, "BlinkCmpScrollBarGutter", { bg = colors.black2 })
hl(0, "BlinkCmpLabel", { fg = colors.white })
hl(0, "BlinkCmpLabelDeprecated", { fg = colors.red, strikethrough = true })
hl(0, "BlinkCmpLabelMatch", { fg = colors.blue, bold = true })
hl(0, "BlinkCmpLabelDetail", { fg = colors.light_grey })
hl(0, "BlinkCmpLabelDescription", { fg = colors.light_grey })
hl(0, "BlinkCmpSource", { fg = colors.grey_fg })
hl(0, "BlinkCmpGhostText", { fg = colors.grey_fg })
hl(0, "BlinkCmpDoc", { bg = colors.black })
hl(0, "BlinkCmpDocBorder", { fg = colors.grey_fg })
hl(0, "BlinkCmpDocSeparator", { fg = colors.grey })
hl(0, "BlinkCmpDocCursorLine", { bg = colors.one_bg })
hl(0, "BlinkCmpSignatureHelp", { bg = colors.black })
hl(0, "BlinkCmpSignatureHelpBorder", { fg = colors.grey_fg })
hl(0, "BlinkCmpSignatureHelpActiveParameter", { fg = colors.blue, bold = true })

-- DAP
hl(0, "DapBreakpoint", { fg = colors.red })
hl(0, "DapBreakpointCondition", { fg = colors.yellow })
hl(0, "DapLogPoint", { fg = colors.sky })
hl(0, "DapStopped", { bg = colors.grey })
