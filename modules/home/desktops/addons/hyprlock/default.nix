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

        input-field = [
          {
            size = {
              width = 300;
              height = 60;
            };
            outline_thickness = 4;
            dots_size = 0.2;
            dots_spacing = 0.2;
            dots_center = true;
            fade_on_empty = false;
            placeholder_text = ''<span foreground="##cdd6f4"><i>󰌾 Logged in as </i><span foreground="##cba6f7">$USER</span></span>'';
            hide_input = false;
            fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
            position = {
              x = -0;
              y = -35;
            };
            halign = "center";
            valign = "center";
          }
        ];

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

        background = [
          {
            path = "${config.stylix.image}";
          }
        ];
      };
    };
  };
}
