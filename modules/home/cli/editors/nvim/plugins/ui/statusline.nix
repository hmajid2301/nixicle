{
  programs.nixvim = {
    plugins.lualine = {
      enable = true;
      settings = {
        options = {
          globalstatus = true;
          icons_enabled = true;
          theme = "catppuccin";
          section_separators = {
            right = "";
            left = "▊ ";
          };
          component_separators = {
            left = "";
            right = "";
          };
        };

        sections = {
          lualine_a = [
            {
              __unkeyed-1 = "mode";
              icon = " ";
              color = {
                gui = "bold";
              };
            }
          ];
          lualine_b = [
            {
              __unkeyed-1 = "filetype";
              icon_only = true;
              colored = true;
              padding = {
                left = 1;
                right = 0;
              };
            }
            {
              __unkeyed-1 = "filename";
              color = {
                fg = "#FFF";
              };
            }
          ];
          lualine_c = [
            {
              __unkeyed-1 = "branch";
              padding = {
                left = 2;
                right = 0;
              };
              icon = "";
              colored = false;
              color = {
                gui = "bold";
                fg = "#605f6f";
              };
            }
            {
              __unkeyed-1 = "diff";
              colored = false;
              color = {
                gui = "bold";
                fg = "#605f6f";
              };
              symbols = {
                added = " ";
                modified = " ";
                removed = " ";
              };
            }
          ];
          lualine_x = [
            {
              __unkeyed-1 = "diagnostics";
              color = {
                fg = "#605f6f";
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
            }
            {
              __unkeyed-1.__raw =
                # lua
                ''
                  function()
                     return (vim.t.maximized and " ") or ""
                  end
                '';
              color = {
                fg = "#2d2c3c";
                bg = "#CBA6F7";
                gui = "bold";
              };
              separator = {
                left = "";
              };
            }
          ];
          lualine_y = [
            {
              __unkeyed-1.__raw =
                # lua
                ''
                  function()
                      local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
                      local clients = vim.lsp.get_active_clients()
                      if next(clients) == nil then
                          return "None"
                      end

                      local msg = ""
                      for _, client in ipairs(clients) do
                          local filetypes = client.config.filetypes
                          if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
                              msg = msg .. client.name .. " "
                          end
                      end

                      if msg then
                        return msg
                      else
                        return "None"
                      end

                    end
                '';
              icon = {
                __unkeyed-1 = " ";
                color = {
                  fg = "#2d2c3c";
                  bg = "#8bc2f0";
                };
              };
              padding = {
                left = 0;
                right = 0;
              };
              separator = {
                left = "";
              };
              color = {
                bg = "#2d2c3c";
                fg = "#FFF";
              };
            }
            {
              __unkeyed-1 = "location";
              icon = {
                __unkeyed-1 = " ";
                color = {
                  fg = "#2d2c3c";
                  bg = "#F38BA8";
                };
              };
              padding = {
                left = 0;
                right = 1;
              };
              separator = {
                left = "";
              };
              color = {
                bg = "#2d2c3c";
                fg = "#FFF";
              };
            }
          ];
          lualine_z = [
            {
              __unkeyed-1 = "progress";
              icon = {
                __unkeyed-1 = " ";
                # TODO: use variable colours
                color = {
                  fg = "#2d2c3c";
                  bg = "#ABE9B3";
                };
              };
              padding = {
                left = 0;
                right = 0;
              };
              separator = {
                left = "";
              };
              color = {
                bg = "#2d2c3c";
                fg = "#ABE9B3";
              };
            }
          ];
        };
      };
    };
  };
}
