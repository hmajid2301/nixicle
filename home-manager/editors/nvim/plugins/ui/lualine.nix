{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      lualine-lsp-progress
    ];

    plugins.lualine = {
      enable = true;
      globalstatus = true;
      disabledFiletypes.statusline = ["alpha" "NvimTree"];
      extensions = ["nvim-tree"];
      sectionSeparators = {
        right = "";
        left = " ";
      };
      # componentSeparators = {
      #   left = "";
      #   right = "";
      # };
      # TODO: Add dap debugger
      # https://www.lazyvim.org/plugins/ui#lualinenvim
      sections = {
        lualine_a = [
          {
            name = "mode";
          }
        ];
        lualine_b = [
          {
            name = "filetype";
            extraConfig = {
              icon_only = true;
              colored = false;
              color = {
                fg = "#D9E0EE";
                bg = "#2f2e3e";
              };
              separator = "";
              padding = {
                left = 1;
                right = 0;
              };
            };
          }
          {
            name = "filename";
            extraConfig = {
              color = {
                fg = "#D9E0EE";
                bg = "#2f2e3e";
              };
              icon_enabled = true;
            };
          }
        ];
        lualine_c = [
          {
            name = "branch";
            extraConfig = {
              icon = "";
              colored = false;
              color = {
                fg = "#605f6f";
                bg = "#2f2e3e";
              };
            };
          }
          {
            name = "diff";
            extraConfig = {
              colored = false;
              color = {
                fg = "#605f6f";
                bg = "#2f2e3e";
              };
              symbols = {
                added = " ";
                modified = " ";
                removed = " ";
              };
            };
          }
        ];
        lualine_x = [
          {
            name = "diagnostics";
            extraConfig = {
              symbols = {
                error = " ";
                warn = " ";
                hint = "󰛩 ";
                info = "󰋼 ";
              };
            };
          }
          # {
          #   name.__raw =
          #     # lua
          #     ''
          #       function()
          #           local msg = ""
          #           local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
          #           local clients = vim.lsp.get_active_clients()
          #           if next(clients) == nil then
          #               return msg
          #           end
          #           for _, client in ipairs(clients) do
          #               local filetypes = client.config.filetypes
          #               if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
          #                   return client.name
          #               end
          #           end
          #           return msg
          #       end
          #     '';
          #   icon = " ";
          #   color.fg = "#ffffff";
          # }
          {
            name = "lsp_progress";
            extraConfig = {
              display_components = ["lsp_client_name" "spinner"];
              spinner_symbols = ["" "󰪞" "󰪟" "󰪠" "󰪢" "󰪣" "󰪤" "󰪥"];
            };
          }
        ];
        lualine_y = [
          {
            name = "location";
            extraConfig = {
              icon_enabled = true;
              icon = "";
            };
          }
        ];
        lualine_z = [
          {
            name = "progress";
            extraConfig = {
              icon_enabled = true;
              icon = [""];
            };
          }
        ];
      };
    };
  };
}
