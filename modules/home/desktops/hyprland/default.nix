{delib, ...}:
delib.module {
  name = "desktops-hyprland";

  options.desktops.hyprland = with delib; {
    enable = boolOption false;
    execOnceExtras = listOfOption lib.types.str [];
  };

  home.always = {config, lib, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.desktops.hyprland;
  in
  mkIf cfg.enable {
    nix.settings = {
      trusted-substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };

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
