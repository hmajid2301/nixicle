{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.desktops.addons.hyprlock;
in {
  options.desktops.addons.hyprlock = with types; {
    enable = mkBoolOpt false "Whether to enable the hyprlock";
  };

  config = mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          disable_loading_bar = true;
          hide_cursor = true;
        };

        label = [
          {
            text = ''cmd[update:43200000] echo "$(date +"%A, %d %B %Y")"'';
            font_size = 25;
            position = {
              x = -30;
              y = -150;
            };
            halign = "right";
            valign = "top";
          }
          {
            text = ''cmd[update:30000] echo "$(date +"%R")"'';
            font_size = 90;
            position = {
              x = -30;
              y = 0;
            };
            halign = "right";
            valign = "top";
          }
        ];
      };
    };
  };
}
