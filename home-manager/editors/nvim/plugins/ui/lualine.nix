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
      theme = {
        normal = {
          a = {
            fg = "#1E1D2D";
            bg = "#89B4FA";
          };
          b = {
            fg = "#D9E0EE";
            bg = "#2f2e3e";
          };
          c = {
            fg = "#D9E0EE";
            bg = "#232232";
          };
        };

        insert = {
          a = {
            fg = "#1E1D2D";
            bg = "#c7a0dc";
          };
        };
        visual = {
          a = {
            fg = "#1E1D2D";
            bg = "#89DCEB";
          };
        };
        replace = {
          a = {
            fg = "#1E1D2D";
            bg = "#F8BD96";
          };
        };
        terminal = {
          a = {
            fg = "#1E1D2D";
            bg = "#ABE9B3";
          };
        };
        command = {
          a = {
            fg = "#1E1D2D";
            bg = "#ABE9B3";
          };
        };
        confirm = {
          a = {
            fg = "#1E1D2D";
            bg = "#B5E8E0";
          };
        };
        select = {
          a = {
            fg = "#1E1D2D";
            bg = "#89B4FA";
          };
        };

        inactive = {
          b = {
            fg = "#D9E0EE";
            bg = "#2f2e3e";
          };
          c = {
            fg = "#D9E0EE";
            bg = "#232232";
          };
        };
      };
      sectionSeparators = {
        right = "";
        left = " ";
        #left = "▊ ";
      };
      componentSeparators = {
        left = "";
        right = "";
      };
      # TODO: Add dap debugger
      # https://www.lazyvim.org/plugins/ui#lualinenvim
      sections = {
        lualine_a = [
          {
            name = "mode";
            extraConfig = {
              color = {
                gui = "bold";
              };
              fmt.__raw =
                # lua
                ''
                  function(str)
                            return " " .. str
                  end
                '';
            };
          }
        ];
        lualine_b = [
          {
            name = "filetype";
            extraConfig = {
              icon_only = true;
              colored = false;
              separator = "";
              padding = {
                left = 1;
                right = 0;
              };
            };
          }
          {
            name = "filename";
          }
        ];
        lualine_c = [
          {
            name = "branch";
            extraConfig = {
              padding = {
                left = 2;
                right = 0;
              };
              icon = "";
              colored = false;
              color = {
                fg = "#605f6f";
                bg = "#232232";
                gui = "bold";
              };
            };
          }
          {
            name = "diff";
            extraConfig = {
              colored = false;
              color = {
                fg = "#605f6f";
                bg = "#232232";
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
              color = {
                fg = "#605f6f";
                bg = "#232232";
                gui = "bold";
              };
              diagnostics_color = {
                color_error = {fg = "#F38BA8";};
                color_warn = {fg = "#FAE3B0";};
              };
              symbols = {
                error = " ";
                warn = " ";
              };
            };
          }
          {
            name = "lsp_progress";
            extraConfig = {
              color = {
                fg = "#605f6f";
                bg = "#232232";
                gui = "bold";
              };
              display_components = ["lsp_client_name" "spinner"];
              spinner_symbols = ["" "󰪞" "󰪟" "󰪠" "󰪢" "󰪣" "󰪤" "󰪥"];
            };
          }
        ];
        lualine_y = [
          # TODO: fix this hack for showing icon with colors
          {
            name.__raw =
              # lua
              ''
                function()
                    return "  "
                end
              '';

            padding = {
              left = 0;
              right = 0;
            };
            color = {
              fg = "#2d2c3c";
              bg = "#8bc2f0";
            };
          }
          {
            name.__raw =
              # lua
              ''
                function()
                    local msg = ""
                    local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
                    local clients = vim.lsp.get_active_clients()
                    if next(clients) == nil then
                        return msg
                    end
                    for _, client in ipairs(clients) do
                        local filetypes = client.config.filetypes
                        if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
                            return client.name
                        end
                    end
                    return msg
                end
              '';
            color = {
              fg = "#D9E0EE";
              bg = "#2f2e3e";
              gui = "bold";
            };
          }
          {
            name.__raw =
              # lua
              ''
                function()
                    return " "
                end
              '';

            padding = {
              left = 0;
              right = 0;
            };
            separator = {
              left = "";
            };
            color = {
              fg = "#2d2c3c";
              bg = "#F38BA8";
              gui = "bold";
            };
          }
          {
            name = "location";
            extraConfig = {
              color = {
                fg = "#D9E0EE";
                bg = "#2f2e3e";
              };
            };
          }
        ];
        lualine_z = [
          {
            name.__raw =
              # lua
              ''
                function()
                    return " "
                end
              '';

            padding = {
              left = 0;
              right = 0;
            };
            color = {
              fg = "#2d2c3c";
              bg = "#ABE9B3";
              gui = "bold";
            };
          }
          {
            name = "progress";
            color = {
              bg = "#2d2c3c";
              fg = "#ABE9B3";
            };
          }
        ];
      };
    };
  };
}