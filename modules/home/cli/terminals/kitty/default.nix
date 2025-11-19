{delib, ...}:
delib.module {
  name = "cli-terminals-kitty";

  options.cli.terminals.kitty = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.terminals.kitty;
  in
  mkIf cfg.enable {
    programs.kitty = {
      enable = true;

      extraConfig = ''
        symbol_map U+23FB-U+23FE,U+2665,U+26A1,U+2B58,U+E000-U+E00A,U+E0A0-U+E0A3,U+E0B0-U+E0D4,U+E200-U+E2A9,U+E300-U+E3E3,U+E5FA-U+E6AA,U+E700-U+E7C5,U+EA60-U+EBEB,U+F000-U+F2E0,U+F300-U+F32F,U+F400-U+F4A9,U+F500-U+F8FF,U+F0001-U+F1AF0 Symbols Nerd Font Mono
      '';

      settings = {
        shell = "fish";
        window_padding_width = 10;
        scrollback_lines = 10000;
        show_hyperlink_targets = "no";
        enable_audio_bell = false;
        url_style = "none";
        underline_hyperlinks = "never";
        copy_on_select = "clipboard";
        # symbol_map = let
        #   mappings = [
        #     "U+E000-U+E00A"
        #     "U+F300-U+F313"
        #     "U+E5FA-U+E62B"
        #     "U+E000-U+E00A"
        #     "U+EA60-U+EBEB"
        #     "U+E0A0-U+E0C8"
        #     "U+E0CA"
        #     "U+E0CC-U+E0D4"
        #     "U+E200-U+E2A9"
        #     "U+E300-U+E3E3"
        #     "U+E5FA-U+E6B1"
        #     "U+E700-U+E7C5"
        #     "U+F000-U+F2E0"
        #     "U+F300-U+F372"
        #     "U+F400-U+F532"
        #     "U+F0001-U+F1AF0"
        #   ];
        #   emoji = [
        #     "U+2600-U+26FF"
        #   ];
        # in [
        #   ((builtins.concatStringsSep "," emoji) + " JoyPixels")
        #   ((builtins.concatStringsSep "," mappings) + " Symbols Nerd Font Mono")
        # ];
      };
    };
  };
}
