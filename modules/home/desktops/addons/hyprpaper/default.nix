{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.desktops.addons.hyprpaper;
in {
  options.desktops.addons.hyprpaper = with types; {
    enable = mkBoolOpt false "Whether to enable the hyprpaper config";
  };

  config = mkIf cfg.enable {
    services.hyprpaper = {
      enable = true;
      settings = {
        preloads = [
          "${pkgs.nixicle.wallpapers.Kurzgesagt-Galaxy_2}"
        ];
        wallpapers = [", ${pkgs.nixicle.wallpapers.Kurzgesagt-Galaxy_2}"];
      };
    };
  };
}
