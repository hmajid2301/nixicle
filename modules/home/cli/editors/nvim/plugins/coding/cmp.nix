{
  programs.nixvim = {
    plugins = {
      cmp-buffer = {
        enable = true;
      };

      cmp-emoji = {
        enable = true;
      };

      cmp-nvim-lsp = {
        enable = true;
      };

      cmp-path = {
        enable = true;
      };

      cmp_luasnip = {
        enable = true;
      };

      cmp = {
        enable = true;
        autoEnableSources = false;

        settings = {
          sources = {
            __raw = ''
              cmp.config.sources({
                { name = 'nvim_lsp' },
                { name = 'luasnip' },
                { name = 'path' },
                { name = 'copilot' },
                { name = 'codeium' },
                -- { name = 'ultisnips' },
                -- { name = 'snippy' },
                -- { name = 'vsnip' },
              }, {
                { name = 'buffer' },
              })
            '';
          };
          formatting = {
            fields = ["abbr" "kind" "menu"];
            format =
              # lua
              ''
                function(_, item)
                  local icons = {
                    Namespace = "󰌗",
                    Text = "󰉿",
                    Method = "󰆧",
                    Function = "󰆧",
                    Constructor = "",
                    Field = "󰜢",
                    Variable = "󰀫",
                    Class = "󰠱",
                    Interface = "",
                    Module = "",
                    Property = "󰜢",
                    Unit = "󰑭",
                    Value = "󰎠",
                    Enum = "",
                    Keyword = "󰌋",
                    Snippet = "",
                    Color = "󰏘",
                    File = "󰈚",
                    Reference = "󰈇",
                    Folder = "󰉋",
                    EnumMember = "",
                    Constant = "󰏿",
                    Struct = "󰙅",
                    Event = "",
                    Operator = "󰆕",
                    TypeParameter = "󰊄",
                    Table = "",
                    Object = "󰅩",
                    Tag = "",
                    Array = "[]",
                    Boolean = "",
                    Number = "",
                    Null = "󰟢",
                    String = "󰉿",
                    Calendar = "",
                    Watch = "󰥔",
                    Package = "",
                    Copilot = "",
                    Codeium = "",
                    TabNine = "",
                  }

                  local icon = icons[item.kind] or ""
                  item.kind = string.format("%s %s", icon, item.kind or "")
                  return item
                end
              '';
          };
          mapping = {
            "<C-n>" = "cmp.mapping.select_next_item()";
            "<C-p>" = "cmp.mapping.select_prev_item()";
            "<C-j>" = "cmp.mapping.select_next_item()";
            "<C-k>" = "cmp.mapping.select_prev_item()";
            "<C-d>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.close()";
            "<CR>" = "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = true })";
            "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
          };
          snippet = {
            expand = ''
              function(args)
                require('luasnip').lsp_expand(args.body)
              end
            '';
          };

          window = {
            completion = {
              winhighlight = "FloatBorder:CmpBorder,Normal:CmpPmenu,CursorLine:CmpSel,Search:PmenuSel";
              scrollbar = false;
              sidePadding = 0;
              border = [
                "╭"
                "─"
                "╮"
                "│"
                "╯"
                "─"
                "╰"
                "│"
              ];
            };

            documentation = {
              border = [
                "╭"
                "─"
                "╮"
                "│"
                "╯"
                "─"
                "╰"
                "│"
              ];
              winhighlight = "FloatBorder:CmpBorder,Normal:CmpPmenu,CursorLine:CmpSel,Search:PmenuSel";
            };
          };
        };
      };
    };
  };
}
