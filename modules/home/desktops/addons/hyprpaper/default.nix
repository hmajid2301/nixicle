{
  options,
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.desktop.addons.hyprpaper;
  inherit (inputs) hyprpaper;
in {
  imports = [hyprpaper.homeManagerModules.default];

  options.desktop.addons.hyprpaper = with types; {
    enable = mkBoolOpt false "Whether to enable the hyprpaper config";
  };

  config =
    mkIf cfg.enable {
    };
}
