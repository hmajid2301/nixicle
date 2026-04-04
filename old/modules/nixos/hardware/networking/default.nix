{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.hardware.networking;
in
{
  options.hardware.networking = with types; {
    enable = mkBoolOpt false "Enable networkmanager";
  };

  config = mkIf cfg.enable {
    networking.firewall = {
      enable = true;
    };
    networking.networkmanager = {
      enable = true;
      settings = {
        main = {
          no-auto-default = "*";
        };
      };
    };

    systemd.services.NetworkManager-wait-online = {
      enable = false;
    };

    # environment.persistence."/persist".directories = [
    #   "/etc/NetworkManager"
    # ];
  };
}
