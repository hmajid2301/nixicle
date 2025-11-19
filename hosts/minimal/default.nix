{delib, ...}:
delib.host {
  name = "minimal";
  rice = "catppuccin";

  myconfig = {
    hosts.minimal = {
      type = "iso";
      isIso = true;
      system = "x86_64-linux";
    };
  };

  nixos = {pkgs, lib, config, myconfig, ...}: lib.mkIf (myconfig.host.name == "minimal") {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.wireless.enable = lib.mkForce false;
    networking.networkmanager.enable = true;

    nix.enable = true;
    services = {
      openssh.enable = true;
    };

    system = {
      locale.enable = true;
    };

    user = {
      name = "nixos";
      initialPassword = "1";
    };

    system.stateVersion = "23.11";
  };
}
