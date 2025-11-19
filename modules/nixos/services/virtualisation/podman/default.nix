{
  config,
  lib,
mkOpt ? null,
mkBoolOpt ? null,
enabled ? null,
disabled ? null,
  ...
}:
with lib;
let
  cfg = config.services.virtualisation.podman;
in
{
  options.services.virtualisation.podman = {
    enable = mkEnableOption "Enable podman";
  };

  config = mkIf cfg.enable {
    virtualisation = {
      containers.enable = true;

      podman = {
        enable = true;
        dockerSocket.enable = true;
        dockerCompat = true;
        defaultNetwork.settings = {
          dns_enabled = true;
        };
      };
    };

    networking.firewall.enable = true;
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
    };
  };
}
