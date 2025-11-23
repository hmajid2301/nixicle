{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;

with types;
let
  cfg = config.desktops.hyprland;
in
{
  imports = [
    ./config.nix
    ./keybindings.nix
    ./windowrules.nix
  ];

  options.desktops.hyprland = {
    enable = mkEnableOption "Enable hyprland window manager";
    execOnceExtras = mkOpt (listOf str) [ ] "Extra programs to exec once";
  };

  config = mkIf cfg.enable {
    desktops.addons = {
      kanshi.enable = true;
      rofi.enable = true;
      dankMaterialShell.enable = true;
      wlsunset.enable = true;
      hypridle.enable = true;

      # pyprland.enable = true;
      # swaync.enable = true;
      # waybar.enable = true;
      wlogout.enable = true;
      hyprpaper.enable = true;
      hyprlock.enable = true;
    };
  };
}
