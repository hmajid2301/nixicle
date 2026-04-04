{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.nixicle;

let
  cfg = config.roles.gaming;
in
{
  options.roles.gaming = with types; {
    enable = mkBoolOpt false "Whether or not to manage gaming configuration";
  };

  config = mkIf cfg.enable {
    programs.mangohud = {
      enable = false;
      enableSessionWide = true;
      settings = {
        cpu_load_change = true;
      };
    };

    home.packages = with pkgs; [
      lutris
      bottles
    ];
  };
}
