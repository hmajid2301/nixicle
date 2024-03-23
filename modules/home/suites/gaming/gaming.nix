{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.programs.gaming;
in {
  options.system.nix = with types; {
    enable = mkBoolOpt false "Whether or not to manage nix configuration";
  };

  config = mkIf cfg.enable {
    programs.mangohud = {
      enable = true;
      enableSessionWide = true;
      settings = {
        full = true;
        no_display = true;
        cpu_load_change = true;
      };
    };

    home.packages = with pkgs; [
      lutris
      cartridges
      bottles
      adwsteamgtk
    ];
  };
}
