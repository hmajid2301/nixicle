{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  inherit (config.colorScheme) palette;
  cfg = config.cli.terminals.alacritty;
in {
  options.cli.terminals.alacritty = with types; {
    enable = mkBoolOpt false "enable alacritty terminal emulator";
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
            monospace = "MonoLisa Nerd Font";
            style = "Regular";
          };
          bold = {
            monospace = "MonoLisa Nerd Font";
            style = "Bold";
          };
          italic = {
            monospace = "MonoLisa Nerd Font";
            style = "Italic";
          };
          size = 14.0;
        };
        colors = {
          primary = {
            background = "#${palette.base00}";
            foreground = "#${palette.base05}";
            dim_foreground = "#${palette.base05}";
            bright_foreground = "#${palette.base05}";
          };
          cursor = {
            text = "#${palette.base00}";
            cursor = "#${palette.base06}";
          };
          vi_mode_cursor = {
            text = "#${palette.base00}";
            cursor = "#${palette.base07}";
          };
          search = {
            matches = {
              foreground = "#${palette.base00}";
              background = "#A5ADCE";
            };
            focused_match = {
              foreground = "#${palette.base00}";
              background = "#${palette.base0B}";
            };
            footer_bar = {
              foreground = "#${palette.base00}";
              background = "#A5ADCE";
            };
          };
          hints = {
            start = {
              foreground = "#${palette.base00}";
              background = "#${palette.base0A}";
            };
            end = {
              foreground = "#${palette.base00}";
              background = "#A5ADCE";
            };
          };
          selection = {
            text = "#${palette.base00}";
            background = "#${palette.base06}";
          };
          normal = {
            black = "#51576D";
            red = "#${palette.base08}";
            green = "#${palette.base0B}";
            yellow = "#${palette.base0A}";
            blue = "#${palette.base0D}";
            magenta = "#F4B8E4";
            cyan = "#${palette.base0C}";
            white = "#B5BFE2";
          };
          bright = {
            black = "#626880";
            red = "#${palette.base08}";
            green = "#${palette.base0B}";
            yellow = "#${palette.base0A}";
            blue = "#${palette.base0D}";
            magenta = "#F4B8E4";
            cyan = "#${palette.base0C}";
            white = "#A5ADCE";
          };
          dim = {
            black = "#51576D";
            red = "#${palette.base08}";
            green = "#${palette.base0B}";
            yellow = "#${palette.base0A}";
            blue = "#${palette.base0D}";
            magenta = "#F4B8E4";
            cyan = "#${palette.base0C}";
            white = "#B5BFE2";
          };
          indexed_colors = [
            {
              index = 16;
              color = "#EF9F76";
            }
            {
              index = 17;
              color = "#${palette.base06}";
            }
          ];
        };
      };
    };
  };
}
