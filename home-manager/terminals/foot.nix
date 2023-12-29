{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.terminals.foot;
in {
  options.modules.terminals.foot = {
    enable = mkEnableOption "enable foot terminal emulator";
  };

  config = mkIf cfg.enable {
    programs.foot = {
      enable = true;

      settings = {
        colors = {
          foreground = "${config.colorscheme.colors.base05}"; # Text
          background = "${config.colorscheme.colors.base00}"; # Base

          regular0 = "${config.colorscheme.colors.base03}"; # Surface 1
          regular1 = "${config.colorscheme.colors.base08}"; # red
          regular2 = "${config.colorscheme.colors.base0B}"; # green
          regular4 = "${config.colorscheme.colors.base0A}"; # yellow
          regular3 = "${config.colorscheme.colors.base0D}"; # blue
          regular5 = "f4b8e4"; # pink
          regular6 = "${config.colorscheme.colors.base0C}"; # teal
          regular7 = "b5bfe2"; # subtext 1

          bright0 = "${config.colorscheme.colors.base04}"; # Surface 2
          bright1 = "${config.colorscheme.colors.base08}"; # red
          bright2 = "${config.colorscheme.colors.base0B}"; # green
          bright4 = "${config.colorscheme.colors.base0A}"; # yellow
          bright3 = "${config.colorscheme.colors.base0D}"; # blue
          bright5 = "f4b8e4"; # pink
          bright6 = "${config.colorscheme.colors.base0C}"; # teal
          bright7 = "a5adce"; # subtext 0
        };

        main = {
          term = "foot";
          font = "${config.my.settings.fonts.monospace}:size=14, JoyPixels:size=14";
          shell = "${config.my.settings.default.shell}";
          pad = "30x30";
          selection-target = "clipboard";
        };

        scrollback = {
          lines = 10000;
        };
      };
    };
  };
}
