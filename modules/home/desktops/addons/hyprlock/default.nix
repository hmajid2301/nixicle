{
  inputs,
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.custom.desktop.addons.hyprlock;
  inherit (inputs) hyprlock;
in {
  imports = [hyprlock.homeManagerModules.default];

  options.custom.desktop.addons.hyprlock = with types; {
    enable = mkBoolOpt false "Whether to enable the hyprlock";
  };

  config = mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;
      # package = pkgs.hyprlock;

      # input_field = {
      #   outer_color = "rgb(24, 25, 38)";
      #   inner_color = "rgb(91, 96, 120)";
      #   font_color = "rgb(202, 211, 245)";
      #   halign = "center";
      #   valign = "center";
      #   size.width = 300;
      #   size.height = 40;
      # };

      # label = {
      #   text = "$TIME, $USER";
      #   color = "rgb(237, 135, 150)";
      #   font_family = "FiraCode";
      #   font_size = 72;
      #   halign = "center";
      #   valign = "center";
      # };

      backgrounds = [
        {
          path = "/home/sab/Pictures/wallpaper.png";
        }
      ];
    };
  };
}
