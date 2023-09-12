{ config, lib, ... }:

with lib;
let
  cfg = config.modules.terminals.alacritty;
in
{
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
            family = config.fontProfiles.monospace.family;
            style = "Regular";
          };
          bold = {
            family = config.fontProfiles.monospace.family;
            style = "Bold";
          };
          italic = {
            family = config.fontProfiles.monospace.family;
            style = "Italic";
          };
          size = 14.0;
        };
        # TODO: move to nix colors
        colors = {
          primary = {
            background = "#303446";
            foreground = "#C6D0F5";
            dim_foreground = "#C6D0F5";
            bright_foreground = "#C6D0F5";
          };
          cursor = {
            text = "#303446";
            cursor = "#F2D5CF";
          };
          vi_mode_cursor = {
            text = "#303446";
            cursor = "#BABBF1";
          };
          search = {
            matches = {
              foreground = "#303446";
              background = "#A5ADCE";
            };
            focused_match = {
              foreground = "#303446";
              background = "#A6D189";
            };
            footer_bar = {
              foreground = "#303446";
              background = "#A5ADCE";
            };
          };
          hints = {
            start = {
              foreground = "#303446";
              background = "#E5C890";
            };
            end = {
              foreground = "#303446";
              background = "#A5ADCE";
            };
          };
          selection = {
            text = "#303446";
            background = "#F2D5CF";
          };
          normal = {
            black = "#51576D";
            red = "#E78284";
            green = "#A6D189";
            yellow = "#E5C890";
            blue = "#8CAAEE";
            magenta = "#F4B8E4";
            cyan = "#81C8BE";
            white = "#B5BFE2";
          };
          bright = {
            black = "#626880";
            red = "#E78284";
            green = "#A6D189";
            yellow = "#E5C890";
            blue = "#8CAAEE";
            magenta = "#F4B8E4";
            cyan = "#81C8BE";
            white = "#A5ADCE";
          };
          dim = {
            black = "#51576D";
            red = "#E78284";
            green = "#A6D189";
            yellow = "#E5C890";
            blue = "#8CAAEE";
            magenta = "#F4B8E4";
            cyan = "#81C8BE";
            white = "#B5BFE2";
          };
          indexed_colors = [
            {
              index = 16;
              color = "#EF9F76";
            }
            {
              index = 17;
              color = "#F2D5CF";
            }
          ];
        };
      };
    };
  };

}
