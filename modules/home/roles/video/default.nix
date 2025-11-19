{
inputs,
  config,
  pkgs,
  lib,
  mkOpt ? null,
  mkBoolOpt ? null,
  enabled ? null,
  disabled ? null,
  ...
}:
with lib;

let cfg = config.roles.video;
in {
  options.roles.video = with types; {
    enable =
      mkBoolOpt false "Whether or not to manage video editting and recording";
  };

  config = mkIf cfg.enable {
    xdg.configFile."obs-studio/themes".source =
      "${inputs.catppuccin-obs}/themes";

    programs.obs-studio = { enable = true; };

    home.packages = with pkgs; [
      audacity
      kdePackages.kdenlive
      davinci-resolve-studio
    ];
  };
}
