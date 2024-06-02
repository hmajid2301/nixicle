{
  lib,
  config,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.roles.server;
in {
  options.roles.server = {
    enable = mkEnableOption "Enable server configuration";
  };

  config = mkIf cfg.enable {
    roles = {
      common.enable = true;
    };

    services = {
      nixicle.avahi.enable = true;
      nixicle.tailscale.enable = true;
      getty.autologinUser = "nixos";
    };

    networking.interfaces.tailscale0.wakeOnLan.enable = true;

    systemd.services.NetworkManager-wait-online.enable = false;
    security.sudo.wheelNeedsPassword = false;

    user = {
      name = "nixos";
      initialPassword = "1";
    };
  };
}
