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
      font = {
        name = "MonoLisa";
        size = 14;
      };

      settings = {
        shell = "fish";
        window_padding_width = 10;
        scrollback_lines = 10000;
        show_hyperlink_targets = "yes";
        enable_audio_bell = false;
        url_style = "none";
        underline_hyperlinks = "never";
        copy_on_select = "clipboard";
      };
    };
  };
}
