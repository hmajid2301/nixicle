{
  programs.nixvim = {
    colorschemes.catppuccin = {
      enable = true;
      flavour = "macchiato";
      # TODO: use nix-colors here
      # or update to use these colors if i prefer them
      colorOverrides = {
        all = {
          white = "#D9E0EE";
          darker_black = "#191828";
          black = "#1E1D2D";
          black2 = "#252434";
          one_bg = "#2d2c3c";
          one_bg2 = "#363545";
          one_bg3 = "#3e3d4d";
          grey = "#474656";
          grey_fg = "#4e4d5d";
          grey_fg2 = "#555464";
          light_grey = "#605f6f";
          red = "#F38BA8";
          baby_pink = "#ffa5c3";
          pink = "#F5C2E7";
          line = "#383747";
          green = "#ABE9B3";
          vibrant_green = "#b6f4be";
          nord_blue = "#8bc2f0";
          blue = "#89B4FA";
          yellow = "#FAE3B0";
          sun = "#ffe9b6";
          purple = "#d0a9e5";
          dark_purple = "#c7a0dc";
          teal = "#B5E8E0";
          orange = "#F8BD96";
          cyan = "#89DCEB";
          statusline_bg = "#232232";
          lightbg = "#2f2e3e";
          pmenu_bg = "#ABE9B3";
          folder_bg = "#89B4FA";
          lavender = "#c7d1ff";

          base00 = "#1E1D2D";
          base01 = "#282737";
          base02 = "#2f2e3e";
          base03 = "#383747";
          base04 = "#414050";
          base05 = "#bfc6d4";
          base06 = "#ccd3e1";
          base07 = "#D9E0EE";
          base08 = "#F38BA8";
          base09 = "#F8BD96";
          base0A = "#FAE3B0";
          base0B = "#ABE9B3";
          base0C = "#89DCEB";
          base0D = "#89B4FA";
          base0E = "#CBA6F7";
          base0F = "#F38BA8";
        };
      };

      customHighlights =
        # lua
        ''
          function(c)
           return {
          	 Normal = { fg = c.base05, bg = c.base00 },
          	 SignColumn = { fg = c.base03, bg = 'NONE', sp = 'NONE',  },
          	 MsgArea = { fg = c.base05, bg = c.base00 },
          	 ModeMsg = { fg = c.base0B, bg = 'NONE' },
          	 MsgSeparator = { fg = c.base05, bg = c.base00 },
          	 SpellBad = { fg = 'NONE', bg = 'NONE', sp = c.base08, undercurl=true, },
          	 SpellCap = { fg = 'NONE', bg = 'NONE', sp = c.base0D, undercurl=true, },
          	 SpellLocal = { fg = 'NONE', bg = 'NONE', sp = c.base0C, undercurl=true, },
          	 SpellRare = { fg = 'NONE', bg = 'NONE', sp = c.base0D, undercurl=true, },
          	 NormalNC = { fg = c.base05, bg = c.base00 },
          	 Pmenu = { fg = 'NONE', bg = c.one_bg },
          	 PmenuSel = { fg = c.black, bg = c.pmenu_bg },
          	 WildMenu = { fg = c.base08, bg = c.base0A },
          	 CursorLineNr = { fg = c.white },
          	 Comment = { fg = c.grey_fg, bg = 'NONE' },
          	 Folded = { fg = c.base03, bg = c.base01 },
          	 FoldColumn = { fg = c.base0C, bg = c.base01 },
          	 LineNr = { fg = c.grey, bg = 'NONE' },
          	 FloatBorder = { fg = c.blue, bg = 'NONE' },
          	 VertSplit = { fg = c.line, bg = 'NONE' },
          	 CursorLine = { fg = 'NONE', bg = c.black2 },
          	 CursorColumn = { fg = 'NONE', bg = c.black2 },
          	 ColorColumn = { fg = 'NONE', bg = c.black2 },
          	 NormalFloat = { fg = 'NONE', bg = c.darker_black },
          	 Visual = { fg = 'NONE', bg = c.base02 },
          	 VisualNOS = { fg = c.base08, bg = 'NONE' },
          	 WarningMsg = { fg = c.base08, bg = 'NONE' },
          	 DiffAdd = { fg = c.vibrant_green, bg = 'NONE' },
          	 DiffChange = { fg = c.blue, bg = 'NONE' },
          	 DiffDelete = { fg = c.red, bg = 'NONE' },
          	 QuickFixLine = { fg = 'NONE', bg = c.base01, sp = 'NONE',  },
          	 PmenuSbar = { fg = 'NONE', bg = c.one_bg },
          	 PmenuThumb = { fg = 'NONE', bg = c.grey },
          	 MatchWord = { fg = c.white, bg = c.grey },
          	 MatchParen = { link = 'MatchWord' },
          	 Cursor = { fg = c.base00, bg = c.base05 },
          	 Conceal = { fg = 'NONE', bg = 'NONE' },
          	 Directory = { fg = c.base0D, bg = 'NONE' },
          	 SpecialKey = { fg = c.base03, bg = 'NONE' },
          	 Title = { fg = c.base0D, bg = 'NONE', sp = 'NONE',  },
          	 ErrorMsg = { fg = c.base08, bg = c.base00 },
          	 Search = { fg = c.base01, bg = c.base0A },
          	 IncSearch = { fg = c.base01, bg = c.base09 },
          	 Substitute = { fg = c.base01, bg = c.base0A, sp = 'NONE',  },
          	 MoreMsg = { fg = c.base0B, bg = 'NONE' },
          	 Question = { fg = c.base0D, bg = 'NONE' },
          	 NonText = { fg = c.base03, bg = 'NONE' },
          	 Variable = { fg = c.base05, bg = 'NONE' },
          	 String = { fg = c.base0B, bg = 'NONE' },
          	 Character = { fg = c.base08, bg = 'NONE' },
          	 Constant = { fg = c.base08, bg = 'NONE' },
          	 Number = { fg = c.base09, bg = 'NONE' },
          	 Boolean = { fg = c.base09, bg = 'NONE' },
          	 Float = { fg = c.base09, bg = 'NONE' },
          	 Identifier = { fg = c.base08, bg = 'NONE', sp = 'NONE',  },
          	 Function = { fg = c.base0D, bg = 'NONE' },
          	 Operator = { fg = c.base05, bg = 'NONE', sp = 'NONE',  },
          	 Type = { fg = c.base0A, bg = 'NONE', sp = 'NONE',  },
          	 StorageClass = { fg = c.base0A, bg = 'NONE' },
          	 Structure = { fg = c.base0E, bg = 'NONE' },
          	 Typedef = { fg = c.base0A, bg = 'NONE' },
          	 Keyword = { fg = c.base0E, bg = 'NONE' },
          	 Statement = { fg = c.base08, bg = 'NONE' },
          	 Conditional = { fg = c.base0E, bg = 'NONE' },
          	 Repeat = { fg = c.base0A, bg = 'NONE' },
          	 Label = { fg = c.base0A, bg = 'NONE' },
          	 Exception = { fg = c.base08, bg = 'NONE' },
          	 Include = { fg = c.base0D, bg = 'NONE' },
          	 PreProc = { fg = c.base0A, bg = 'NONE' },
          	 Define = { fg = c.base0E, bg = 'NONE', sp = 'NONE',  },
          	 Macro = { fg = c.base08, bg = 'NONE' },
          	 Special = { fg = c.base0C, bg = 'NONE' },
          	 SpecialChar = { fg = c.base0F, bg = 'NONE' },
          	 Tag = { fg = c.base0A, bg = 'NONE' },
          	 Debug = { fg = c.base08, bg = 'NONE' },
          	 Underlined = { fg = c.base0B, bg = 'NONE' },
          	 Bold = { fg = 'NONE', bg = 'NONE', bold=true, },
          	 Italic = { fg = 'NONE', bg = 'NONE', italic=true, },
          	 Ignore = { fg = c.cyan, bg = c.base00, bold=true, },
          	 Todo = { fg = c.base0A, bg = c.base01 },
          	 Error = { fg = c.base00, bg = c.base08 },
          	 TabLine = { fg = c.light_grey, bg = c.line },
          	 TabLineSel = { fg = c.white, bg = c.line },
          	 TabLineFill = { fg = c.line, bg = c.line },

          	 ["@annotation"] = { fg = c.base0F, bg = 'NONE' },
          	 ["@attribute"] = { fg = c.base0A, bg = 'NONE' },
          	 ["@constructor"] = { fg = c.base0C, bg = 'NONE' },
          	 ["@type.builtin"]= { fg = c.base0A, bg = 'NONE' },
          	 ["@conditional"] = { link = 'Conditional' },
          	 ["@exception"] = { fg = c.base08, bg = 'NONE' },
          	 ["@include"] = { link = 'Include' },
          	 ["@keyword.return"] = { fg = c.base0E, bg = 'NONE' },
          	 ["@keyword"] = { fg = c.base0E, bg = 'NONE' },
          	 ["@keyword.function"] = { fg = c.base0E, bg = 'NONE' },
          	 ["@namespace"] = { fg = c.base08, bg = 'NONE' },
          	 ["@constant.builtin"] = { fg = c.base09, bg = 'NONE' },
          	 ["@float"] = { fg = c.base09, bg = 'NONE' },
          	 ["@character"] = { fg = c.base08, bg = 'NONE' },
          	 ["@error"] = { fg = c.base08, bg = 'NONE' },
          	 ["@function"] = { fg = c.base0D, bg = 'NONE' },
          	 ["@function.builtin"] = { fg = c.base0D, bg = 'NONE' },
          	 ["@method"] = { fg = c.base0D, bg = 'NONE' },
          	 ["@constant.macro"] = { fg = c.base08, bg = 'NONE' },
          	 ["@function.macro"] = { fg = c.base08, bg = 'NONE' },
          	 ["@variable"] = { fg = c.base05, bg = 'NONE' },
          	 ["@variable.builtin"] = { fg = c.base09, bg = 'NONE' },
          	 ["@property"] = { fg = c.base08, bg = 'NONE' },
          	 ["@field"] = { fg = c.base0D, bg = 'NONE' },
          	 ["@parameter"] = { fg = c.base08, bg = 'NONE' },
          	 ["@parameter.reference"] = { fg = c.base05, bg = 'NONE' },
          	 ["@symbol"] = { fg = c.base0B, bg = 'NONE' },
          	 ["@text"] = { fg = c.base05, bg = 'NONE' },
          	 ["@punctuation.delimiter"] = { fg = c.base0F, bg = 'NONE' },
          	 ["@tag.delimiter"] = { fg = c.base0F, bg = 'NONE' },
          	 ["@tag.attribute"] = { link = '@Property' },
          	 ["@punctuation.bracket"] = { fg = c.base0F, bg = 'NONE' },
          	 ["@punctuation.special"] = { fg = c.base08, bg = 'NONE' },
          	 ["@string.regex"] = { fg = c.base0C, bg = 'NONE' },
          	 ["@string.escape"] = { fg = c.base0C, bg = 'NONE' },
          	 ["@emphasis"] = { fg = c.base09, bg = 'NONE' },
          	 ["@literal"] = { fg = c.base09, bg = 'NONE' },
          	 ["@text.uri"] = { fg = c.base09, bg = 'NONE' },
          	 ["@keyword.operator"] = { fg = c.base0E, bg = 'NONE' },
          	 ["@strong"] = { fg = 'NONE', bg = 'NONE', bold=true, },
          	 ["@scope"] = { fg = 'NONE', bg = 'NONE', bold=true, },
          	 TreesitterContext = { link = 'CursorLine' },

          	 markdownBlockquote = { fg = c.green, bg = 'NONE' },
          	 markdownCode = { fg = c.orange, bg = 'NONE' },
          	 markdownCodeBlock = { fg = c.orange, bg = 'NONE' },
          	 markdownCodeDelimiter = { fg = c.orange, bg = 'NONE' },
          	 markdownH1 = { fg = c.blue, bg = 'NONE' },
          	 markdownH2 = { fg = c.blue, bg = 'NONE' },
          	 markdownH3 = { fg = c.blue, bg = 'NONE' },
          	 markdownH4 = { fg = c.blue, bg = 'NONE' },
          	 markdownH5 = { fg = c.blue, bg = 'NONE' },
          	 markdownH6 = { fg = c.blue, bg = 'NONE' },
          	 markdownHeadingDelimiter = { fg = c.blue, bg = 'NONE' },
          	 markdownHeadingRule = { fg = c.base05, bg = 'NONE', bold=true, },
          	 markdownId = { fg = c.purple, bg = 'NONE' },
          	 markdownIdDeclaration = { fg = c.blue, bg = 'NONE' },
          	 markdownIdDelimiter = { fg = c.light_grey, bg = 'NONE' },
          	 markdownLinkDelimiter = { fg = c.light_grey, bg = 'NONE' },
          	 markdownBold = { fg = c.blue, bg = 'NONE', bold=true, },
          	 markdownItalic = { fg = 'NONE', bg = 'NONE', italic=true, },
          	 markdownBoldItalic = { fg = c.yellow, bg = 'NONE', bold=true, italic=true, },
          	 markdownListMarker = { fg = c.blue, bg = 'NONE' },
          	 markdownOrderedListMarker = { fg = c.blue, bg = 'NONE' },
          	 markdownRule = { fg = c.base01, bg = 'NONE' },
          	 markdownUrl = { fg = c.cyan, bg = 'NONE', underline=true, },
          	 markdownLinkText = { fg = c.blue, bg = 'NONE' },
          	 markdownFootnote = { fg = c.orange, bg = 'NONE' },
          	 markdownFootnoteDefinition = { fg = c.orange, bg = 'NONE' },
          	 markdownEscape = { fg = c.yellow, bg = 'NONE' },

          	 WhichKey = { fg = c.blue, bg = 'NONE' },
          	 WhichKeySeperator = { fg = c.light_grey, bg = 'NONE' },
          	 WhichKeyDesc = { fg = c.red, bg = 'NONE' },
          	 WhichKeyGroup = { fg = c.green, bg = 'NONE' },
          	 WhichKeyValue = { fg = c.green, bg = 'NONE' },
          	 WhichKeyFloat = { link = 'NormalFloat' },

          	 SignAdd = { fg = c.green, bg = 'NONE' },
          	 SignChange = { fg = c.blue, bg = 'NONE' },
          	 SignDelete = { fg = c.red, bg = 'NONE' },
          	 GitSignsAdd = { fg = c.green, bg = 'NONE' },
          	 GitSignsChange = { fg = c.blue, bg = 'NONE' },
          	 GitSignsDelete = { fg = c.red, bg = 'NONE' },

          	 DiagnosticError = { fg = c.base08, bg = 'NONE' },
          	 DiagnosticWarning = { fg = c.base09, bg = 'NONE' },
          	 DiagnosticHint = { fg = c.purple, bg = 'NONE' },
          	 DiagnosticWarn = { fg = c.yellow, bg = 'NONE' },
          	 DiagnosticInfo = { fg = c.green, bg = 'NONE' },
          	 LspDiagnosticsDefaultError = { fg = c.base08, bg = 'NONE' },
          	 LspDiagnosticsDefaultWarning = { fg = c.base09, bg = 'NONE' },
          	 LspDiagnosticsDefaultInformation = { fg = c.sun, bg = 'NONE' },
          	 LspDiagnosticsDefaultInfo = { fg = c.sun, bg = 'NONE' },
          	 LspDiagnosticsDefaultHint = { fg = c.purple, bg = 'NONE' },
          	 LspDiagnosticsVirtualTextError = { fg = c.base08, bg = 'NONE' },
          	 LspDiagnosticsVirtualTextWarning = { fg = c.base09, bg = 'NONE' },
          	 LspDiagnosticsVirtualTextInformation = { fg = c.sun, bg = 'NONE' },
          	 LspDiagnosticsVirtualTextInfo = { fg = c.sun, bg = 'NONE' },
          	 LspDiagnosticsVirtualTextHint = { fg = c.purple, bg = 'NONE' },
          	 LspDiagnosticsFloatingError = { fg = c.base08, bg = 'NONE' },
          	 LspDiagnosticsFloatingWarning = { fg = c.base09, bg = 'NONE' },
          	 LspDiagnosticsFloatingInformation = { fg = c.sun, bg = 'NONE' },
          	 LspDiagnosticsFloatingInfo = { fg = c.sun, bg = 'NONE' },
          	 LspDiagnosticsFloatingHint = { fg = c.purple, bg = 'NONE' },
          	 DiagnosticSignError = { fg = c.base08, bg = 'NONE' },
          	 DiagnosticSignWarning = { fg = c.base09, bg = 'NONE' },
          	 DiagnosticSignInformation = { fg = c.sun, bg = 'NONE' },
          	 DiagnosticSignInfo = { fg = c.sun, bg = 'NONE' },
          	 DiagnosticSignHint = { fg = c.purple, bg = 'NONE' },
          	 LspDiagnosticsSignError = { fg = c.base08, bg = 'NONE' },
          	 LspDiagnosticsSignWarning = { fg = c.base09, bg = 'NONE' },
          	 LspDiagnosticsSignInformation = { fg = c.sun, bg = 'NONE' },
          	 LspDiagnosticsSignInfo = { fg = c.sun, bg = 'NONE' },
          	 LspDiagnosticsSignHint = { fg = c.purple, bg = 'NONE' },
          	 LspDiagnosticsError = { fg = c.base08, bg = 'NONE' },
          	 LspDiagnosticsWarning = { fg = c.base09, bg = 'NONE' },
          	 LspDiagnosticsInformation = { fg = c.sun, bg = 'NONE' },
          	 LspDiagnosticsInfo = { fg = c.sun, bg = 'NONE' },
          	 LspDiagnosticsHint = { fg = c.purple, bg = 'NONE' },
          	 LspDiagnosticsUnderlineError = { fg = 'NONE', bg = 'NONE', underline=true, },
          	 LspDiagnosticsUnderlineWarning = { fg = 'NONE', bg = 'NONE', underline=true, },
          	 LspDiagnosticsUnderlineInformation = { fg = 'NONE', bg = 'NONE', underline=true, },
          	 LspDiagnosticsUnderlineInfo = { fg = 'NONE', bg = 'NONE', underline=true, },
          	 LspDiagnosticsUnderlineHint = { fg = 'NONE', bg = 'NONE', underline=true, },
          	 LspReferenceRead = { fg = 'NONE', bg = '#2e303b' },
          	 LspReferenceText = { fg = 'NONE', bg = '#2e303b' },
          	 LspReferenceWrite = { fg = 'NONE', bg = '#2e303b' },
          	 LspCodeLens = { fg = c.base04, bg = 'NONE', italic=true, },
          	 LspCodeLensSeparator = { fg = c.base04, bg = 'NONE', italic=true, },

          	 TelescopeNormal = { fg = 'NONE', bg = c.darker_black },
          	 TelescopePreviewTitle = { fg = c.black, bg = c.green, bold=true, },
          	 TelescopePromptTitle = { fg = c.black, bg = c.red, bold=true, },
          	 TelescopeResultsTitle = { fg = c.darker_black, bg = c.darker_black, bold=true, },
          	 TelescopeSelection = { fg = c.white, bg = c.black2 },
          	 TelescopeBorder = { fg = c.darker_black, bg = c.darker_black },
          	 TelescopePromptBorder = { fg = c.black2, bg = c.black2 },
          	 TelescopePromptNormal = { fg = c.white, bg = c.black2 },
          	 TelescopePromptPrefix = { fg = c.red, bg = c.black2 },
          	 TelescopeResultsDiffAdd = { fg = c.green, bg = 'NONE' },
          	 TelescopeResultsDiffChange = { fg = c.blue, bg = 'NONE' },
          	 TelescopeResultsDiffDelete = { fg = c.red, bg = 'NONE' },

          	 NvimTreeFolderIcon = { fg = c.blue, bg = 'NONE' },
          	 NvimTreeIndentMarker = { fg = c.grey_fg, bg = 'NONE' },
          	 NvimTreeNormal = { fg = 'NONE', bg = c.darker_black },
          	 NvimTreeVertSplit = { fg = c.darker_black, bg = c.darker_black },
          	 NvimTreeFolderName = { fg = c.blue, bg = 'NONE' },
          	 NvimTreeOpenedFolderName = { fg = c.blue, bg = 'NONE', bold=true, italic=true, },
          	 NvimTreeEmptyFolderName = { fg = c.grey, bg = 'NONE', italic=true, },
          	 NvimTreeGitIgnored = { fg = c.grey, bg = 'NONE', italic=true, },
          	 NvimTreeImageFile = { fg = c.light_grey, bg = 'NONE' },
          	 NvimTreeSpecialFile = { fg = c.orange, bg = 'NONE' },
          	 NvimTreeEndOfBuffer = { fg = c.darker_black, bg = 'NONE' },
          	 NvimTreeCursorLine = { fg = 'NONE', bg = '#282b37' },
          	 NvimTreeGitignoreIcon = { fg = c.red, bg = 'NONE' },
          	 NvimTreeGitStaged = { fg = c.vibrant_green, bg = 'NONE' },
          	 NvimTreeGitNew = { fg = c.vibrant_green, bg = 'NONE' },
          	 NvimTreeGitRenamed = { fg = c.vibrant_green, bg = 'NONE' },
          	 NvimTreeGitDeleted = { fg = c.red, bg = 'NONE' },
          	 NvimTreeGitMerge = { fg = c.blue, bg = 'NONE' },
          	 NvimTreeGitDirty = { fg = c.blue, bg = 'NONE' },
          	 NvimTreeSymlink = { fg = c.cyan, bg = 'NONE' },
          	 NvimTreeRootFolder = { fg = c.base05, bg = 'NONE', bold=true, },
          	 NvimTreeExecFile = { fg = c.green, bg = 'NONE' },

          	 BufferCurrent = { fg = c.base05, bg = c.base00 },
          	 BufferCurrentIndex = { fg = c.base05, bg = c.base00 },
          	 BufferCurrentMod = { fg = c.sun, bg = c.base00 },
          	 BufferCurrentSign = { fg = c.purple, bg = c.base00 },
          	 BufferCurrentTarget = { fg = c.red, bg = c.base00, bold=true, },
          	 BufferVisible = { fg = c.base05, bg = c.base00 },
          	 BufferVisibleIndex = { fg = c.base05, bg = c.base00 },
          	 BufferVisibleMod = { fg = c.sun, bg = c.base00 },
          	 BufferVisibleSign = { fg = c.grey, bg = c.base00 },
          	 BufferVisibleTarget = { fg = c.red, bg = c.base00, bold=true, },
          	 BufferInactive = { fg = c.grey, bg = c.darker_black },
          	 BufferInactiveIndex = { fg = c.grey, bg = c.darker_black },
          	 BufferInactiveMod = { fg = c.sun, bg = c.darker_black },
          	 BufferInactiveSign = { fg = c.grey, bg = c.darker_black },
          	 BufferInactiveTarget = { fg = c.red, bg = c.darker_black, bold=true, },

          	 StatusLine = { fg = c.line, bg = c.statusline_bg },
          	 StatusLineNC = { fg = 'NONE', bg = c.statusline_bg },
          	 StatusLineSeparator = { fg = c.line, bg = 'NONE' },
          	 StatusLineTerm = { fg = c.line, bg = 'NONE' },
          	 StatusLineTermNC = { fg = c.line, bg = 'NONE' },

          	 IndentBlanklineContextChar = { fg = c.grey, bg = 'NONE' },
          	 IndentBlanklineContextStart = { fg = 'NONE', bg = c.one_bg2 },
          	 IndentBlanklineChar = { fg = c.line, bg = 'NONE' },
          	 IndentBlanklineSpaceChar = { fg = c.line, bg = 'NONE' },
          	 IndentBlanklineSpaceCharBlankline = { fg = c.sun, bg = 'NONE' },

          	 DashboardHeader = { fg = c.blue, bg = 'NONE' },
          	 DashboardCenter = { fg = c.purple, bg = 'NONE' },
          	 DashboardFooter = { fg = c.cyan, bg = 'NONE' },

          	 AlphaHeader = { fg = c.blue, bg = 'NONE' },
          	 AlphaButtons = { fg = c.purple, bg = 'NONE' },
          	 AlphaFooter = { fg = c.cyan, bg = 'NONE' },

          	 CmpItemAbbr = { fg = c.white },
          	 CmpItemAbbrMatch = { fg = c.blue, bold = true },
          	 CmpDoc = { bg = c.darker_black },
          	 CmpBorder = { fg = c.grey_fg },
          	 CmpDocBorder = { fg = c.darker_black, bg = c.darker_black },
          	 CmpPmenu = { bg = c.black },
          	 CmpSel = { link = "PmenuSel", bold = true },
          	 CmpItemAbbrDeprecated = { fg = c.grey, bg = 'NONE', strikethrough=true, },
          	 CmpItemAbbrMatch = { fg = c.blue, bg = 'NONE' },
          	 CmpItemAbbrMatchFuzzy = { fg = c.blue, bg = 'NONE' },
          	 CmpItemKindFunction = { fg = c.blue, bg = 'NONE' },
          	 CmpItemKindMethod = { fg = c.blue, bg = 'NONE' },
          	 CmpItemKindConstructor = { fg = c.cyan, bg = 'NONE' },
          	 CmpItemKindClass = { fg = c.cyan, bg = 'NONE' },
          	 CmpItemKindEnum = { fg = c.cyan, bg = 'NONE' },
          	 CmpItemKindEvent = { fg = c.yellow, bg = 'NONE' },
          	 CmpItemKindInterface = { fg = c.cyan, bg = 'NONE' },
          	 CmpItemKindStruct = { fg = c.cyan, bg = 'NONE' },
          	 CmpItemKindVariable = { fg = c.red, bg = 'NONE' },
          	 CmpItemKindField = { fg = c.red, bg = 'NONE' },
          	 CmpItemKindProperty = { fg = c.red, bg = 'NONE' },
          	 CmpItemKindEnumMember = { fg = c.orange, bg = 'NONE' },
          	 CmpItemKindConstant = { fg = c.orange, bg = 'NONE' },
          	 CmpItemKindKeyword = { fg = c.purple, bg = 'NONE' },
          	 CmpItemKindModule = { fg = c.cyan, bg = 'NONE' },
          	 CmpItemKindValue = { fg = c.cyan, bg = 'NONE' },
          	 CmpItemKindUnit = { fg = c.base0E, bg = 'NONE' },
          	 CmpItemKindText = { fg = c.base0B, bg = 'NONE' },
          	 CmpItemKindSnippet = { fg = c.yellow, bg = 'NONE' },
          	 CmpItemKindFile = { fg = c.base07, bg = 'NONE' },
          	 CmpItemKindFolder = { fg = c.base07, bg = 'NONE' },
          	 CmpItemKindColor = { fg = c.white, bg = 'NONE' },
          	 CmpItemKindReference = { fg = c.base05, bg = 'NONE' },
          	 CmpItemKindOperator = { fg = c.base05, bg = 'NONE' },
          	 CmpItemKindTypeParameter = { fg = c.base08, bg = 'NONE' },

          	 ToggleTerm1FloatBorder = { fg = c.line, bg = 'NONE' },

          	 IlluminatedWordText = { fg = 'NONE', bg = c.base03, },
          	 IlluminatedWordRead = { fg = 'NONE', bg = c.base03, },
          	 IlluminatedWordWrite = { fg = 'NONE', bg = c.base03, },
           }
          end
        '';
    };
  };
}
