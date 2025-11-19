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
  cfg = config.hardware.networking;
in {
  options.hardware.networking = with types; {
    enable = mkBoolOpt false "Enable networkmanager";
  };

  config = mkIf cfg.enable {
    networking.firewall = {
      enable = true;
    };
    networking.networkmanager.enable = true;
    # environment.persistence."/persist".directories = [
    #   "/etc/NetworkManager"
    # ];
  };
}
