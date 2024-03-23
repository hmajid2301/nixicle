{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.desktops.hyprland;
in {
  imports = with inputs;
    [
      hyprland-nix.homeManagerModules.default
    ]
    ++ lib.snowfall.fs.get-non-default-nix-files ./.;

  options.desktops.hyprland = {
    enable = mkEnableOption "enable hyprland window manager";
  };

  config = mkIf cfg.enable {
    nix.settings = {
      trusted-substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };

    desktops.addons = {
      gtk.enable = true;
      qt.enable = true;
      kanshi.enable = true;
      rofi.enable = true;
      swaylock.enable = true;
      swaync.enable = true;
      waybar.enable = true;
      wlogout.enable = true;
      wlsunset.enable = true;
    };
  };
}
