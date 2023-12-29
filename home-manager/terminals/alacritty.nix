{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.terminals.alacritty;
in {
  options.modules.terminals.alacritty = {
    enable = mkEnableOption "enable alacritty terminal emulator";
  };

  config = mkIf cfg.enable {
    programs.alacritty = {
      enable = true;

      settings = {
        shell = {
          program = "fish";
        };

        window = {
          padding = {
            x = 30;
            y = 30;
          };
          decorations = "none";
        };

        selection = {
          save_to_clipboard = true;
        };

        mouse_bindings = [
          {
            mouse = "Right";
            action = "Paste";
          }
        ];

        env = {
          TERM = "xterm-256color";
        };

        font = {
          normal = {
            inherit (config.my.settings.fonts) monospace;
            style = "Regular";
          };
          bold = {
            inherit (config.my.settings.fonts) monospace;
            style = "Bold";
          };
          italic = {
            inherit (config.my.settings.fonts) monospace;
            style = "Italic";
          };
          size = 14.0;
        };
        colors = {
          primary = {
            background = "#${config.colorscheme.colors.base00}";
            foreground = "#${config.colorscheme.colors.base05}";
            dim_foreground = "#${config.colorscheme.colors.base05}";
            bright_foreground = "#${config.colorscheme.colors.base05}";
          };
          cursor = {
            text = "#${config.colorscheme.colors.base00}";
            cursor = "#${config.colorscheme.colors.base06}";
          };
          vi_mode_cursor = {
            text = "#${config.colorscheme.colors.base00}";
            cursor = "#${config.colorscheme.colors.base07}";
          };
          search = {
            matches = {
              foreground = "#${config.colorscheme.colors.base00}";
              background = "#A5ADCE";
            };
            focused_match = {
              foreground = "#${config.colorscheme.colors.base00}";
              background = "#${config.colorscheme.colors.base0B}";
            };
            footer_bar = {
              foreground = "#${config.colorscheme.colors.base00}";
              background = "#A5ADCE";
            };
          };
          hints = {
            start = {
              foreground = "#${config.colorscheme.colors.base00}";
              background = "#${config.colorscheme.colors.base0A}";
            };
            end = {
              foreground = "#${config.colorscheme.colors.base00}";
              background = "#A5ADCE";
            };
          };
          selection = {
            text = "#${config.colorscheme.colors.base00}";
            background = "#${config.colorscheme.colors.base06}";
          };
          normal = {
            black = "#51576D";
            red = "#${config.colorscheme.colors.base08}";
            green = "#${config.colorscheme.colors.base0B}";
            yellow = "#${config.colorscheme.colors.base0A}";
            blue = "#${config.colorscheme.colors.base0D}";
            magenta = "#F4B8E4";
            cyan = "#${config.colorscheme.colors.base0C}";
            white = "#B5BFE2";
          };
          bright = {
            black = "#626880";
            red = "#${config.colorscheme.colors.base08}";
            green = "#${config.colorscheme.colors.base0B}";
            yellow = "#${config.colorscheme.colors.base0A}";
            blue = "#${config.colorscheme.colors.base0D}";
            magenta = "#F4B8E4";
            cyan = "#${config.colorscheme.colors.base0C}";
            white = "#A5ADCE";
          };
          dim = {
            black = "#51576D";
            red = "#${config.colorscheme.colors.base08}";
            green = "#${config.colorscheme.colors.base0B}";
            yellow = "#${config.colorscheme.colors.base0A}";
            blue = "#${config.colorscheme.colors.base0D}";
            magenta = "#F4B8E4";
            cyan = "#${config.colorscheme.colors.base0C}";
            white = "#B5BFE2";
          };
          indexed_colors = [
            {
              index = 16;
              color = "#EF9F76";
            }
            {
              index = 17;
              color = "#${config.colorscheme.colors.base06}";
            }
          ];
        };
      };
    };
  };
}
