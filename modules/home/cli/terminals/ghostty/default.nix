{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.cli.terminals.ghostty;
in {
  options.cli.terminals.ghostty = {
    enable = mkEnableOption "enable ghostty terminal emulator";
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      enableFishIntegration = true;

      settings = {
        theme = "catppuccin-mocha";
        font-family = "${config.stylix.fonts.monospace.name}";
        command = "fish";
        gtk-titlebar = false;
        gtk-tabs-location = "hidden";
        gtk-single-instance = true;
        font-size = 14;
        window-padding-x = 6;
        window-padding-y = 6;
        copy-on-select = "clipboard";
        cursor-style = "block";
        confirm-close-surface = false;
        keybind = [
          "ctrl+shift+plus=increase_font_size:1"
        ];
      };
    };
  };
}
