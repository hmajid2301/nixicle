{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.desktops.addons.hyprpanel;
in {
  options.desktops.addons.hyprpanel = {
    enable = mkEnableOption "Enable hyprpanel";
  };
  imports = [inputs.hyprpanel.homeManagerModules.hyprpanel];

  config = mkIf cfg.enable {
    programs.hyprpanel = {
      enable = true;
      systemd.enable = true;
      overwrite.enable = true;
    };
  };
}
