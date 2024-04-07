{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.cli.terminals.kitty;
in {
  options.cli.terminals.kitty = with types; {
    enable = mkBoolOpt false "enable kitty terminal emulator";
  };

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;

      theme = "Catppuccin-Mocha";
      font = {
        name = "MonoLisa Nerd Font";
        size = 14;
      };

      settings = {
        background_opacity = "0.9";
        scrollback_lines = 10000;
        show_hyperlink_targets = "yes";
        enable_audio_bell = false;
        url_style = "none";
        underline_hyperlinks = "never";
      };
    };
  };
}
