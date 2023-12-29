{lib, ...}: {
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;
}
