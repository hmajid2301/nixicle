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
    nix.settings = {
      extra-substituters = [ "https://hyprland.cachix.org" ];
      extra-trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };

    desktops.addons = {
      kanshi.enable = true;
      rofi.enable = true;
      dms.enable = true;
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
