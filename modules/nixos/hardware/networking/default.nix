{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.hardware.networking;
in {
  options.hardware.networking = with types; {
    enable = mkBoolOpt false "Enable networkmanager";
  };

  config = mkIf cfg.enable {
    networking.firewall = {
      enable = true;
      # allowedTCPPortRanges = [
      #   {
      #     from = 1714;
      #     to = 1764;
      #   }
      # ];
      # allowedUDPPortRanges = [
      #   {
      #     from = 1714;
      #     to = 1764;
      #   }
      # ];
    };
    networking.networkmanager.enable = true;
    # environment.persistence."/persist".directories = [
    #   "/etc/NetworkManager"
    # ];
  };
}
