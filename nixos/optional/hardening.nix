{ pkgs, ... }: {
  networking.firewall = {
    enable = true;
    allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
    allowedUDPPortRanges = [{ from = 1714; to = 1764; }];
  };

  #environment.memoryAllocator.provider = "scudo";
  systemd.coredump.enable = false;
  services.clamav.daemon.enable = true;
  services.clamav.updater.enable = true;
  services.clamav.scanner.enable = true;
  services.opensnitch.enable = true;

  environment.systemPackages = [
    pkgs.opensnitch-ui
  ];
}
