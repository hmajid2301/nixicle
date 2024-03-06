let
  colors = {
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
    maroon = "#eba0ac";
    baby_pink = "#ffa5c3";
    pink = "#F5C2E7";
    line = "#383747";
    green = "#ABE9B3";
    vibrant_green = "#b6f4be";
    nord_blue = "#8bc2f0";
    mauve = "#cba6f7";
    blue = "#89B4FA";
    yellow = "#FAE3B0";
    sun = "#ffe9b6";
    purple = "#d0a9e5";
    dark_purple = "#c7a0dc";
    teal = "#B5E8E0";
    peach = "#fab387";
    orange = "#F8BD96";
    cyan = "#89DCEB";
    sky = "#89DCEB";
    statusline_bg = "#232232";
    lightbg = "#2f2e3e";
    pmenu_bg = "#ABE9B3";
    folder_bg = "#89B4FA";
    lavender = "#c7d1ff";
    text = "#cdd6f4";
    surface2 = "#585b70";
    surface1 = "#45475a";
    surface0 = "#313244";

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
in {
  programs.nixvim = {
    colorschemes.catppuccin = {
      enable = true;
      flavour = "mocha";
      colorOverrides.all = colors;
      integrations = {
        alpha = true;
        # cmp = true;
        dashboard = true;
        # dap = {
        #   enable_ui = true;
        #   enabled = true;
        # };
        gitsigns = true;
        illuminate.enabled = true;
        flash = true;
        indent_blankline.enabled = true;
        mini.enabled = true;
        navic.enabled = true;
        telescope.enabled = true;
      };
    };

    extraConfigLua = ''
      require("dap")

      local sign = vim.fn.sign_define

      sign("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = ""})
      sign("DapBreakpointCondition", { text = "●", texthl = "DapBreakpointCondition", linehl = "", numhl = ""})
      sign("DapLogPoint", { text = "◆", texthl = "DapLogPoint", linehl = "", numhl = ""})
      sign('DapStopped', { text='', texthl='DapStopped', linehl='DapStopped', numhl= 'DapStopped' })
    '';

    highlight = with colors; {
      IndentBlanklineContextChar = {
        fg = grey;
        bg = null;
      };
      IndentBlanklineContextStart = {
        fg = null;
        bg = one_bg2;
      };
      IndentBlanklineChar = {
        fg = line;
        bg = null;
      };
      IndentBlanklineSpaceChar = {
        fg = line;
        bg = null;
      };
      IndentBlanklineSpaceCharBlankline = {
        fg = sun;
        bg = null;
      };
      IlluminatedWordText = {
        fg = null;
        bg = base03;
      };
      IlluminatedWordRead = {
        fg = null;
        bg = base03;
      };
      IlluminatedWordWrite = {
        fg = null;
        bg = base03;
      };
    };

    highlightOverride = with colors; {
      Normal = {
        fg = base05;
        bg = base00;
      };
      SignColumn = {
        fg = base03;
        bg = null;
        sp = null;
      };
      MsgArea = {
        fg = base05;
        bg = base00;
      };
      ModeMsg = {
        fg = base0B;
        bg = null;
      };
      MsgSeparator = {
        fg = base05;
        bg = base00;
      };
      SpellBad = {
        fg = null;
        bg = null;
        sp = base08;
        undercurl = true;
      };
      SpellCap = {
        fg = null;
        bg = null;
        sp = base0D;
        undercurl = true;
      };
      SpellLocal = {
        fg = null;
        bg = null;
        sp = base0C;
        undercurl = true;
      };
      SpellRare = {
        fg = null;
        bg = null;
        sp = base0D;
        undercurl = true;
      };
      NormalNC = {
        fg = base05;
        bg = base00;
      };
      Pmenu = {
        fg = null;
        bg = one_bg;
      };
      PmenuSel = {
        fg = black;
        bg = pmenu_bg;
      };
      WildMenu = {
        fg = base08;
        bg = base0A;
      };
      CursorLineNr = {fg = white;};
      Comment = {
        fg = grey_fg;
        bg = null;
      };
      Folded = {
        fg = base03;
        bg = base01;
      };
      FoldColumn = {
        fg = base0C;
        bg = base01;
      };
      LineNr = {
        fg = grey;
        bg = null;
      };
      FloatBorder = {
        fg = blue;
        bg = null;
      };
      VertSplit = {
        fg = line;
        bg = null;
      };
      CursorLine = {
        fg = null;
        bg = black2;
      };
      CursorColumn = {
        fg = null;
        bg = black2;
      };
      ColorColumn = {
        fg = null;
        bg = black2;
      };
      NormalFloat = {
        fg = null;
        bg = darker_black;
      };
      Visual = {
        fg = null;
        bg = base02;
      };
      VisualNOS = {
        fg = base08;
        bg = null;
      };
      WarningMsg = {
        fg = base08;
        bg = null;
      };
      DiffAdd = {
        fg = vibrant_green;
        bg = null;
      };
      DiffChange = {
        fg = blue;
        bg = null;
      };
      DiffDelete = {
        fg = red;
        bg = null;
      };
      QuickFixLine = {
        fg = null;
        bg = base01;
        sp = null;
      };
      PmenuSbar = {
        fg = null;
        bg = one_bg;
      };
      PmenuThumb = {
        fg = null;
        bg = grey;
      };
      MatchWord = {
        fg = white;
        bg = grey;
      };
      MatchParen = {link = "MatchWord";};
      Cursor = {
        fg = base00;
        bg = base05;
      };
      Conceal = {
        fg = null;
        bg = null;
      };
      Directory = {
        fg = base0D;
        bg = null;
      };
      SpecialKey = {
        fg = base03;
        bg = null;
      };
      Title = {
        fg = base0D;
        bg = null;
        sp = null;
      };
      ErrorMsg = {
        fg = base08;
        bg = base00;
      };
      Search = {
        fg = base01;
        bg = base0A;
      };
      IncSearch = {
        fg = base01;
        bg = base09;
      };
      Substitute = {
        fg = base01;
        bg = base0A;
        sp = null;
      };
      MoreMsg = {
        fg = base0B;
        bg = null;
      };
      Question = {
        fg = base0D;
        bg = null;
      };
      NonText = {
        fg = base03;
        bg = null;
      };
      Variable = {
        fg = base05;
        bg = null;
      };
      String = {
        fg = base0B;
        bg = null;
      };
      Character = {
        fg = base08;
        bg = null;
      };
      Constant = {
        fg = base08;
        bg = null;
      };
      Number = {
        fg = base09;
        bg = null;
      };
      Boolean = {
        fg = base09;
        bg = null;
      };
      Float = {
        fg = base09;
        bg = null;
      };
      Identifier = {
        fg = base08;
        bg = null;
        sp = null;
      };
      Function = {
        fg = base0D;
        bg = null;
      };
      Operator = {
        fg = base05;
        bg = null;
        sp = null;
      };
      Type = {
        fg = base0A;
        bg = null;
        sp = null;
      };
      StorageClass = {
        fg = base0A;
        bg = null;
      };
      Structure = {
        fg = base0E;
        bg = null;
      };
      Typedef = {
        fg = base0A;
        bg = null;
      };
      Keyword = {
        fg = base0E;
        bg = null;
      };
      Statement = {
        fg = base08;
        bg = null;
      };
      Conditional = {
        fg = base0E;
        bg = null;
      };
      Repeat = {
        fg = base0A;
        bg = null;
      };
      Label = {
        fg = base0A;
        bg = null;
      };
      Exception = {
        fg = base08;
        bg = null;
      };
      Include = {
        fg = base0D;
        bg = null;
      };
      PreProc = {
        fg = base0A;
        bg = null;
      };
      Define = {
        fg = base0E;
        bg = null;
        sp = null;
      };
      Macro = {
        fg = base08;
        bg = null;
      };
      Special = {
        fg = base0C;
        bg = null;
      };
      SpecialChar = {
        fg = base0F;
        bg = null;
      };
      Tag = {
        fg = base0A;
        bg = null;
      };
      Debug = {
        fg = base08;
        bg = null;
      };
      Underlined = {
        fg = base0B;
        bg = null;
      };
      Bold = {
        fg = null;
        bg = null;
        bold = true;
      };
      Italic = {
        fg = null;
        bg = null;
        italic = true;
      };
      Ignore = {
        fg = cyan;
        bg = base00;
        bold = true;
      };
      Todo = {
        fg = base0A;
        bg = base01;
      };
      Error = {
        fg = base00;
        bg = base08;
      };
      TabLine = {
        fg = light_grey;
        bg = line;
      };
      TabLineSel = {
        fg = white;
        bg = line;
      };
      TabLineFill = {
        fg = line;
        bg = line;
      };

      "@annotation" = {
        fg = base0F;
        bg = null;
      };
      "@attribute" = {
        fg = base0A;
        bg = null;
      };
      "@constructor" = {
        fg = base0C;
        bg = null;
      };
      "@type.builtin" = {
        fg = base0A;
        bg = null;
      };
      "@conditional" = {link = "Conditional";};
      "@exception" = {
        fg = base08;
        bg = null;
      };
      "@include" = {link = "Include";};
      "@keyword.return" = {
        fg = base0E;
        bg = null;
      };
      "@keyword" = {
        fg = base0E;
        bg = null;
      };
      "@keyword.function" = {
        fg = base0E;
        bg = null;
      };
      "@namespace" = {
        fg = base08;
        bg = null;
      };
      "@constant.builtin" = {
        fg = base09;
        bg = null;
      };
      "@float" = {
        fg = base09;
        bg = null;
      };
      "@character" = {
        fg = base08;
        bg = null;
      };
      "@error" = {
        fg = base08;
        bg = null;
      };
      "@function" = {
        fg = base0D;
        bg = null;
      };
      "@function.builtin" = {
        fg = base0D;
        bg = null;
      };
      "@method" = {
        fg = base0D;
        bg = null;
      };
      "@constant.macro" = {
        fg = base08;
        bg = null;
      };
      "@function.macro" = {
        fg = base08;
        bg = null;
      };
      "@variable" = {
        fg = base05;
        bg = null;
      };
      "@variable.builtin" = {
        fg = base09;
        bg = null;
      };
      "@property" = {
        fg = base08;
        bg = null;
      };
      "@field" = {
        fg = base0D;
        bg = null;
      };
      "@parameter" = {
        fg = base08;
        bg = null;
      };
      "@parameter.reference" = {
        fg = base05;
        bg = null;
      };
      "@symbol" = {
        fg = base0B;
        bg = null;
      };
      "@text" = {
        fg = base05;
        bg = null;
      };
      "@punctuation.delimiter" = {
        fg = base0F;
        bg = null;
      };
      "@tag.delimiter" = {
        fg = base0F;
        bg = null;
      };
      "@tag.attribute" = {link = "@Property";};
      "@punctuation.bracket" = {
        fg = base0F;
        bg = null;
      };
      "@punctuation.special" = {
        fg = base08;
        bg = null;
      };
      "@string.regex" = {
        fg = base0C;
        bg = null;
      };
      "@string.escape" = {
        fg = base0C;
        bg = null;
      };
      "@emphasis" = {
        fg = base09;
        bg = null;
      };
      "@literal" = {
        fg = base09;
        bg = null;
      };
      "@text.uri" = {
        fg = base09;
        bg = null;
      };
      "@keyword.operator" = {
        fg = base0E;
        bg = null;
      };
      "@strong" = {
        fg = null;
        bg = null;
        bold = true;
      };
      "@scope" = {
        fg = null;
        bg = null;
        bold = true;
      };
      TreesitterContext = {link = "CursorLine";};

      markdownBlockquote = {
        fg = green;
        bg = null;
      };
      markdownCode = {
        fg = orange;
        bg = null;
      };
      markdownCodeBlock = {
        fg = orange;
        bg = null;
      };
      markdownCodeDelimiter = {
        fg = orange;
        bg = null;
      };
      markdownH1 = {
        fg = blue;
        bg = null;
      };
      markdownH2 = {
        fg = blue;
        bg = null;
      };
      markdownH3 = {
        fg = blue;
        bg = null;
      };
      markdownH4 = {
        fg = blue;
        bg = null;
      };
      markdownH5 = {
        fg = blue;
        bg = null;
      };
      markdownH6 = {
        fg = blue;
        bg = null;
      };
      markdownHeadingDelimiter = {
        fg = blue;
        bg = null;
      };
      markdownHeadingRule = {
        fg = base05;
        bg = null;
        bold = true;
      };
      markdownId = {
        fg = purple;
        bg = null;
      };
      markdownIdDeclaration = {
        fg = blue;
        bg = null;
      };
      markdownIdDelimiter = {
        fg = light_grey;
        bg = null;
      };
      markdownLinkDelimiter = {
        fg = light_grey;
        bg = null;
      };
      markdownBold = {
        fg = blue;
        bg = null;
        bold = true;
      };
      markdownItalic = {
        fg = null;
        bg = null;
        italic = true;
      };
      markdownBoldItalic = {
        fg = yellow;
        bg = null;
        bold = true;
        italic = true;
      };
      markdownListMarker = {
        fg = blue;
        bg = null;
      };
      markdownOrderedListMarker = {
        fg = blue;
        bg = null;
      };
      markdownRule = {
        fg = base01;
        bg = null;
      };
      markdownUrl = {
        fg = cyan;
        bg = null;
        underline = true;
      };
      markdownLinkText = {
        fg = blue;
        bg = null;
      };
      markdownFootnote = {
        fg = orange;
        bg = null;
      };
      markdownFootnoteDefinition = {
        fg = orange;
        bg = null;
      };
      markdownEscape = {
        fg = yellow;
        bg = null;
      };

      WhichKey = {
        fg = blue;
        bg = null;
      };
      WhichKeySeperator = {
        fg = light_grey;
        bg = null;
      };
      WhichKeyDesc = {
        fg = red;
        bg = null;
      };
      WhichKeyGroup = {
        fg = green;
        bg = null;
      };
      WhichKeyValue = {
        fg = green;
        bg = null;
      };
      WhichKeyFloat = {link = "NormalFloat";};

      SignAdd = {
        fg = green;
        bg = null;
      };
      SignChange = {
        fg = blue;
        bg = null;
      };
      SignDelete = {
        fg = red;
        bg = null;
      };
      GitSignsAdd = {
        fg = green;
        bg = null;
      };
      GitSignsChange = {
        fg = blue;
        bg = null;
      };
      GitSignsDelete = {
        fg = red;
        bg = null;
      };

      DiagnosticError = {
        fg = base08;
        bg = null;
      };
      DiagnosticWarning = {
        fg = base09;
        bg = null;
      };
      DiagnosticHint = {
        fg = purple;
        bg = null;
      };
      DiagnosticWarn = {
        fg = yellow;
        bg = null;
      };
      DiagnosticInfo = {
        fg = green;
        bg = null;
      };
      LspDiagnosticsDefaultError = {
        fg = base08;
        bg = null;
      };
      LspDiagnosticsDefaultWarning = {
        fg = base09;
        bg = null;
      };
      LspDiagnosticsDefaultInformation = {
        fg = sun;
        bg = null;
      };
      LspDiagnosticsDefaultInfo = {
        fg = sun;
        bg = null;
      };
      LspDiagnosticsDefaultHint = {
        fg = purple;
        bg = null;
      };
      LspDiagnosticsVirtualTextError = {
        fg = base08;
        bg = null;
      };
      LspDiagnosticsVirtualTextWarning = {
        fg = base09;
        bg = null;
      };
      LspDiagnosticsVirtualTextInformation = {
        fg = sun;
        bg = null;
      };
      LspDiagnosticsVirtualTextInfo = {
        fg = sun;
        bg = null;
      };
      LspDiagnosticsVirtualTextHint = {
        fg = purple;
        bg = null;
      };
      LspDiagnosticsFloatingError = {
        fg = base08;
        bg = null;
      };
      LspDiagnosticsFloatingWarning = {
        fg = base09;
        bg = null;
      };
      LspDiagnosticsFloatingInformation = {
        fg = sun;
        bg = null;
      };
      LspDiagnosticsFloatingInfo = {
        fg = sun;
        bg = null;
      };
      LspDiagnosticsFloatingHint = {
        fg = purple;
        bg = null;
      };
      DiagnosticSignError = {
        fg = base08;
        bg = null;
      };
      DiagnosticSignWarning = {
        fg = base09;
        bg = null;
      };
      DiagnosticSignInformation = {
        fg = sun;
        bg = null;
      };
      DiagnosticSignInfo = {
        fg = sun;
        bg = null;
      };
      DiagnosticSignHint = {
        fg = purple;
        bg = null;
      };
      LspDiagnosticsSignError = {
        fg = base08;
        bg = null;
      };
      LspDiagnosticsSignWarning = {
        fg = base09;
        bg = null;
      };
      LspDiagnosticsSignInformation = {
        fg = sun;
        bg = null;
      };
      LspDiagnosticsSignInfo = {
        fg = sun;
        bg = null;
      };
      LspDiagnosticsSignHint = {
        fg = purple;
        bg = null;
      };
      LspDiagnosticsError = {
        fg = base08;
        bg = null;
      };
      LspDiagnosticsWarning = {
        fg = base09;
        bg = null;
      };
      LspDiagnosticsInformation = {
        fg = sun;
        bg = null;
      };
      LspDiagnosticsInfo = {
        fg = sun;
        bg = null;
      };
      LspDiagnosticsHint = {
        fg = purple;
        bg = null;
      };
      LspDiagnosticsUnderlineError = {
        fg = null;
        bg = null;
        underline = true;
      };
      LspDiagnosticsUnderlineWarning = {
        fg = null;
        bg = null;
        underline = true;
      };
      LspDiagnosticsUnderlineInformation = {
        fg = null;
        bg = null;
        underline = true;
      };
      LspDiagnosticsUnderlineInfo = {
        fg = null;
        bg = null;
        underline = true;
      };
      LspDiagnosticsUnderlineHint = {
        fg = null;
        bg = null;
        underline = true;
      };
      LspReferenceRead = {
        fg = null;
        bg = "#2e303b";
      };
      LspReferenceText = {
        fg = null;
        bg = "#2e303b";
      };
      LspReferenceWrite = {
        fg = null;
        bg = "#2e303b";
      };
      LspCodeLens = {
        fg = base04;
        bg = null;
        italic = true;
      };
      LspCodeLensSeparator = {
        fg = base04;
        bg = null;
        italic = true;
      };

      TelescopeNormal = {
        fg = null;
        bg = darker_black;
      };
      TelescopePreviewTitle = {
        fg = black;
        bg = green;
        bold = true;
      };
      TelescopePromptTitle = {
        fg = black;
        bg = red;
        bold = true;
      };
      TelescopeResultsTitle = {
        fg = darker_black;
        bg = darker_black;
        bold = true;
      };
      TelescopeSelection = {
        fg = white;
        bg = black2;
      };
      TelescopeBorder = {
        fg = darker_black;
        bg = darker_black;
      };
      TelescopePromptBorder = {
        fg = black2;
        bg = black2;
      };
      TelescopePromptNormal = {
        fg = white;
        bg = black2;
      };
      TelescopePromptPrefix = {
        fg = red;
        bg = black2;
      };
      TelescopeResultsDiffAdd = {
        fg = green;
        bg = null;
      };
      TelescopeResultsDiffChange = {
        fg = blue;
        bg = null;
      };
      TelescopeResultsDiffDelete = {
        fg = red;
        bg = null;
      };

      NvimTreeFolderIcon = {
        fg = blue;
        bg = null;
      };
      NvimTreeIndentMarker = {
        fg = grey_fg;
        bg = null;
      };
      NvimTreeNormal = {
        fg = null;
        bg = darker_black;
      };
      NvimTreeVertSplit = {
        fg = darker_black;
        bg = darker_black;
      };
      NvimTreeFolderName = {
        fg = blue;
        bg = null;
      };
      NvimTreeOpenedFolderName = {
        fg = blue;
        bg = null;
        bold = true;
        italic = true;
      };
      NvimTreeEmptyFolderName = {
        fg = grey;
        bg = null;
        italic = true;
      };
      NvimTreeGitIgnored = {
        fg = grey;
        bg = null;
        italic = true;
      };
      NvimTreeImageFile = {
        fg = light_grey;
        bg = null;
      };
      NvimTreeSpecialFile = {
        fg = orange;
        bg = null;
      };
      NvimTreeEndOfBuffer = {
        fg = darker_black;
        bg = null;
      };
      NvimTreeCursorLine = {
        fg = null;
        bg = "#282b37";
      };
      NvimTreeGitignoreIcon = {
        fg = red;
        bg = null;
      };
      NvimTreeGitStaged = {
        fg = vibrant_green;
        bg = null;
      };
      NvimTreeGitNew = {
        fg = vibrant_green;
        bg = null;
      };
      NvimTreeGitRenamed = {
        fg = vibrant_green;
        bg = null;
      };
      NvimTreeGitDeleted = {
        fg = red;
        bg = null;
      };
      NvimTreeGitMerge = {
        fg = blue;
        bg = null;
      };
      NvimTreeGitDirty = {
        fg = blue;
        bg = null;
      };
      NvimTreeSymlink = {
        fg = cyan;
        bg = null;
      };
      NvimTreeRootFolder = {
        fg = base05;
        bg = null;
        bold = true;
      };
      NvimTreeExecFile = {
        fg = green;
        bg = null;
      };

      BufferCurrent = {
        fg = base05;
        bg = base00;
      };
      BufferCurrentIndex = {
        fg = base05;
        bg = base00;
      };
      BufferCurrentMod = {
        fg = sun;
        bg = base00;
      };
      BufferCurrentSign = {
        fg = purple;
        bg = base00;
      };
      BufferCurrentTarget = {
        fg = red;
        bg = base00;
        bold = true;
      };
      BufferVisible = {
        fg = base05;
        bg = base00;
      };
      BufferVisibleIndex = {
        fg = base05;
        bg = base00;
      };
      BufferVisibleMod = {
        fg = sun;
        bg = base00;
      };
      BufferVisibleSign = {
        fg = grey;
        bg = base00;
      };
      BufferVisibleTarget = {
        fg = red;
        bg = base00;
        bold = true;
      };
      BufferInactive = {
        fg = grey;
        bg = darker_black;
      };
      BufferInactiveIndex = {
        fg = grey;
        bg = darker_black;
      };
      BufferInactiveMod = {
        fg = sun;
        bg = darker_black;
      };
      BufferInactiveSign = {
        fg = grey;
        bg = darker_black;
      };
      BufferInactiveTarget = {
        fg = red;
        bg = darker_black;
        bold = true;
      };

      StatusLine = {
        fg = line;
        bg = statusline_bg;
      };
      StatusLineNC = {
        fg = null;
        bg = statusline_bg;
      };
      StatusLineSeparator = {
        fg = line;
        bg = null;
      };
      StatusLineTerm = {
        fg = line;
        bg = null;
      };
      StatusLineTermNC = {
        fg = line;
        bg = null;
      };

      DashboardHeader = {
        fg = blue;
        bg = null;
      };
      DashboardCenter = {
        fg = purple;
        bg = null;
      };
      DashboardFooter = {
        fg = cyan;
        bg = null;
      };

      AlphaHeader = {
        fg = blue;
        bg = null;
      };
      AlphaButtons = {
        fg = purple;
        bg = null;
      };
      AlphaFooter = {
        fg = cyan;
        bg = null;
      };

      CmpItemAbbr = {fg = white;};
      CmpDoc = {bg = darker_black;};
      CmpBorder = {fg = grey_fg;};
      CmpDocBorder = {
        fg = darker_black;
        bg = darker_black;
      };
      CmpPmenu = {bg = black;};
      CmpSel = {
        link = "PmenuSel";
        bold = true;
      };
      CmpItemAbbrDeprecated = {
        fg = grey;
        bg = null;
        strikethrough = true;
      };
      CmpItemAbbrMatch = {
        fg = blue;
        bold = true;
        bg = null;
      };
      CmpItemAbbrMatchFuzzy = {
        fg = blue;
        bg = null;
      };
      CmpItemKindFunction = {
        fg = blue;
        bg = null;
      };
      CmpItemKindMethod = {
        fg = blue;
        bg = null;
      };
      CmpItemKindConstructor = {
        fg = cyan;
        bg = null;
      };
      CmpItemKindClass = {
        fg = cyan;
        bg = null;
      };
      CmpItemKindEnum = {
        fg = cyan;
        bg = null;
      };
      CmpItemKindEvent = {
        fg = yellow;
        bg = null;
      };
      CmpItemKindInterface = {
        fg = cyan;
        bg = null;
      };
      CmpItemKindStruct = {
        fg = cyan;
        bg = null;
      };
      CmpItemKindVariable = {
        fg = red;
        bg = null;
      };
      CmpItemKindField = {
        fg = red;
        bg = null;
      };
      CmpItemKindProperty = {
        fg = red;
        bg = null;
      };
      CmpItemKindEnumMember = {
        fg = orange;
        bg = null;
      };
      CmpItemKindConstant = {
        fg = orange;
        bg = null;
      };
      CmpItemKindKeyword = {
        fg = purple;
        bg = null;
      };
      CmpItemKindModule = {
        fg = cyan;
        bg = null;
      };
      CmpItemKindValue = {
        fg = cyan;
        bg = null;
      };
      CmpItemKindUnit = {
        fg = base0E;
        bg = null;
      };
      CmpItemKindText = {
        fg = base0B;
        bg = null;
      };
      CmpItemKindSnippet = {
        fg = yellow;
        bg = null;
      };
      CmpItemKindFile = {
        fg = base07;
        bg = null;
      };
      CmpItemKindFolder = {
        fg = base07;
        bg = null;
      };
      CmpItemKindColor = {
        fg = white;
        bg = null;
      };
      CmpItemKindReference = {
        fg = base05;
        bg = null;
      };
      CmpItemKindOperator = {
        fg = base05;
        bg = null;
      };
      CmpItemKindTypeParameter = {
        fg = base08;
        bg = null;
      };

      # nvim-dap
      DapBreakpoint = {fg = red;};
      DapBreakpointCondition = {fg = yellow;};
      DapLogPoint = {fg = sky;};
      DapStopped = {bg = grey;};

      # nvim-dap-ui
      DAPUIScope = {fg = sky;};
      DAPUIType = {fg = mauve;};
      DAPUIValue = {fg = sky;};
      DAPUIVariable = {fg = text;};
      DapUIModifiedValue = {fg = peach;};
      DapUIDecoration = {fg = sky;};
      DapUIThread = {fg = green;};
      DapUIStoppedThread = {fg = sky;};
      DapUISource = {fg = lavender;};
      DapUILineNumber = {fg = sky;};
      DapUIFloatBorder = {fg = sky;};

      DapUIWatchesEmpty = {fg = maroon;};
      DapUIWatchesValue = {fg = green;};
      DapUIWatchesError = {fg = maroon;};

      DapUIBreakpointsPath = {fg = sky;};
      DapUIBreakpointsInfo = {fg = green;};
      DapUIBreakpointsCurrentLine = {
        fg = green;
        bold = true;
      };
      DapUIBreakpointsDisabledLine = {fg = surface2;};

      DapUIStepOver = {fg = blue;};
      DapUIStepInto = {fg = blue;};
      DapUIStepBack = {fg = blue;};
      DapUIStepOut = {fg = blue;};
      DapUIStop = {fg = red;};
      DapUIPlayPause = {fg = green;};
      DapUIRestart = {fg = green;};
      DapUIUnavailable = {fg = surface1;};
    };
  };
}
