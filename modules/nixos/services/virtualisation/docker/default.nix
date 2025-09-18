{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.virtualisation.docker;
in
{
  options.services.virtualisation.docker = {
    enable = mkEnableOption "Enable Docker";
  };

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune.enable = true;
      storageDriver = "btrfs";
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };

    users.extraGroups.docker.members = [ "haseeb" ];

    environment.systemPackages = with pkgs; [
      docker-compose
    ];

    networking.firewall.enable = true;
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
    };
  };
}