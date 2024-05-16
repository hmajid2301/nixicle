{lib, ...}: {
  imports = [
    ./hardware-configuration.nix
    # TODO: Get this work with Disko
    # ./disks.nix
  ];

  roles = {
    kubernetes.enable = true;
  };

  system.boot.enable = lib.mkForce false;
  hardware.raspberry-pi-4.enable = true;

  system.stateVersion = "23.11";
}
