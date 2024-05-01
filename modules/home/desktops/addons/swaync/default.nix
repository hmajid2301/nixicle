{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.desktops.addons.swaync;
in {
  options.desktops.addons.swaync = {
    enable = mkEnableOption "Enable sway notification center";
  };

  config = mkIf cfg.enable {
    services.swaync = {
      enable = true;
      settings = {};
      style = builtins.readFile ./swaync.css;
    };
  };
}
