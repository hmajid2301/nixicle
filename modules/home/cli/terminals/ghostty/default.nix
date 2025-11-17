{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.cli.terminals.ghostty;
in
{
  options.cli.terminals.ghostty = {
    enable = mkEnableOption "enable ghostty terminal emulator";
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      enableFishIntegration = true;

      settings = {
        command = "fish";
        gtk-titlebar = false;
        gtk-tabs-location = "hidden";
        gtk-single-instance = true;
        window-padding-x = 6;
        window-padding-y = 6;
        copy-on-select = "clipboard";
        cursor-style = "block";
        confirm-close-surface = false;

        # Override bright green to have better contrast with light text
        # This fixes the readability issue with pre-commit "Passed" messages
        palette = "2=#40a02b"; # Green with better contrast

        keybind = [
          "ctrl+shift+plus=increase_font_size:1"
          "ctrl+shift+minus=decrease_font_size:1"
          "ctrl+shift+0=reset_font_size"
          # Claude Code Shift+Enter binding
          "shift+enter=text:\u001b[13;2u"
        ];
      };
    };
  };
}
