{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.nixos.extraSecurity;
in {
  options.modules.nixos.extraSecurity = {
    enable = mkEnableOption "Enable hardened nixos";
  };

  config = mkIf cfg.enable {
    security = {
      protectKernelImage = false;
      tpm2 = {
        enable = true;
        pkcs11.enable = true;
        tctiEnvironment.enable = true;
      };
    };

    networking.firewall = {
      enable = true;
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
    };

    systemd.coredump.enable = false;
    #environment.memoryAllocator.provider = "scudo";
    # services.clamav.daemon.enable = true;
    # services.clamav.updater.enable = true;
    # services.clamav.scanner.enable = true;
    services.opensnitch.enable = true;

    environment.systemPackages = [
      pkgs.opensnitch-ui
    ];
  };
}
