{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.roles.gaming;
in {
  options.roles.gaming = with types; {
    enable = mkBoolOpt false "Enable the gaming suite";
  };

  config = mkIf cfg.enable {
    hardware = {
      xpadneo.enable = true;
      xone.enable = true;

      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
        extraPackages = with pkgs; [
          mesa
        ];
      };
    };

    services.ratbagd.enable = true;

    programs = {
      gamemode.enable = true;
      gamescope.enable = true;
      steam = {
        enable = true;
        package = pkgs.steam.override {
          extraPkgs = p:
            with p; [
              mangohud
              gamemode
            ];
        };
        dedicatedServer.openFirewall = true;
        remotePlay.openFirewall = true;
        gamescopeSession.enable = true;
        extraCompatPackages = with pkgs; [
          proton-ge-bin
        ];
      };
    };

    environment.systemPackages = with pkgs; [
      winetricks
      wineWowPackages.waylandFull
    ];
  };
}
