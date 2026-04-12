_: {
  den.aspects.alacritty = {
    homeManager = _: {
      programs.alacritty = {
        enable = true;
        settings = {
          shell.program = "fish";
          window = {
            padding = {
              x = 30;
              y = 30;
            };
            decorations = "none";
          };
          selection.save_to_clipboard = true;
          mouse_bindings = [
            {
              mouse = "Right";
              action = "Paste";
            }
          ];
          env.TERM = "xterm-256color";
        };
      };
    };
  };
}
