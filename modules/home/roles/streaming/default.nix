{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.roles.streaming;
in {
  options.roles.streaming = with types; {
    enable = mkBoolOpt false "Whether or not to manage streaming configuration";
  };

  config = mkIf cfg.enable {
    programs.obs-studio = {
      enable = true;
    };
  };
}
