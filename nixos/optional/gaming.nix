{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.nixos.gaming;
in {
  imports = [
    inputs.nix-gaming.nixosModules.steamCompat
  ];

  options.modules.nixos.gaming = {
    enable = mkEnableOption "Enable gaming features";
  };

  config = mkIf cfg.enable {
    nix.settings = {
      substituters = ["https://nix-gaming.cachix.org"];
      trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
    };

    programs.gamemode.enable = true;
    programs.gamescope.enable = true;
    programs.steam = {
      enable = true;
      dedicatedServer.openFirewall = true;
      remotePlay.openFirewall = true;
      gamescopeSession.enable = true;
      extraCompatPackages = [
        inputs.nix-gaming.packages.${pkgs.system}.proton-ge
      ];
    };

    environment.systemPackages = with pkgs; [
      winetricks
      wineWowPackages.waylandFull
    ];
  };
}
