{pkgs, ...}: {
  services.printing.enable = true;
  hardware.enableAllFirmware = true;
  hardware.keyboard.zsa.enable = true;
  services.hardware.bolt.enable = true;
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true; # Solaar.

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

  environment.systemPackages = with pkgs; [
    headsetcontrol2
    solaar
  ];

  services.udev.packages = with pkgs; [
    headsetcontrol2
    logitech-udev-rules
    solaar
  ];

  services.dbus.enable = true;
  services.dbus.packages = [pkgs.gcr];
  services.geoclue2.enable = true;
  environment.pathsToLink = [
    "/share/fish"
    "/share/zsh"
    "/share/bash"
  ];
}
