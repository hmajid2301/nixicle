{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.roles.video;
in {
  options.roles.video = with types; {
    enable = mkBoolOpt false "Whether or not to manage video editting and recording";
  };

  config = mkIf cfg.enable {
    programs.obs-studio = {
      enable = true;
    };

    home.packages = with pkgs; [
      audacity
      shotcut
    ];
  };
}
