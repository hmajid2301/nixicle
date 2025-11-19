{delib, ...}:
delib.module {
  name = "cli-terminals-alacritty";

  options.cli.terminals.alacritty = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.terminals.alacritty;
  in
  mkIf cfg.enable {
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
      };
    };
  };
}
