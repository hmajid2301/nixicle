{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.desktops.addons.swaync;
in {
  options.desktops.addons.swaync = {
    enable = mkEnableOption "Enable sway notification center";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      swaynotificationcenter
    ];

    xdg.configFile."swaync/style.css".source = ./swaync.css;
    xdg.configFile."swaync/config.json".source = ./swaync.json;
  };
}
