{ pkgs
, inputs
, outputs
, ...
}: {

  services.printing.enable = true;
  hardware.enableAllFirmware = true;
  hardware.keyboard.zsa.enable = true;
  services.hardware.bolt.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
    allowedUDPPortRanges = [{ from = 1714; to = 1764; }];
  };

  services.dbus.enable = true;
  services.dbus.packages = [ pkgs.gcr ];
  services.geoclue2.enable = true;
  environment.pathsToLink = [
    "/share/fish"
    "/share/zsh"
    "/share/bash"
  ];
}
