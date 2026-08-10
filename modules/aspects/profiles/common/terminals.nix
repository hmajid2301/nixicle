{ lib, ... }:
{
  den.aspects.commonTerminals = {
    homeManager = { pkgs, ... }: {
      programs.foot = {
        enable = true;
        settings = {
          main = {
            shell = "fish";
            pad = "15x15";
            selection-target = "clipboard";
          };
          scrollback.lines = 10000;
        };
      };

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
          keybind = [
            "ctrl+shift+plus=increase_font_size:1"
            "ctrl+shift+minus=decrease_font_size:1"
            "ctrl+shift+0=reset_font_size"
            "shift+enter=text:\\u001b[13;2u"
          ];
        };
      };
    };
  };
}
