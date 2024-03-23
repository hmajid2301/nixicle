{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.desktops.addons.hyprpaper;
  inherit (inputs) hyprpaper;
in {
  imports = [hyprpaper.homeManagerModules.default];

  options.desktops.addons.hyprpaper = with types; {
    enable = mkBoolOpt false "Whether to enable the hyprpaper config";
  };

  config = mkIf cfg.enable {
    services.hyprpaper = {
      enable = true;
      preloads = [
        "${pkgs.nixicle.wallpapers.Kurzgesagt-Galaxy_2}"
      ];
      wallpapers = [", ${pkgs.nixicle.wallpapers.Kurzgesagt-Galaxy_2}"];
    };
  };
}
