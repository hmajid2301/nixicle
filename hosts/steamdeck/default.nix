{delib, ...}:
delib.host {
  name = "steamdeck";
  rice = "catppuccin";

  myconfig = {
    hosts.steamdeck = {
      type = "desktop";
      isDesktop = true;
      system = "x86_64-linux";
    };
  };

  nixos = {pkgs, lib, config, myconfig, ...}: lib.mkIf (myconfig.host.name == "steamdeck") {
    # Steam Deck system configuration
    # Note: Hardware-configuration.nix should be generated on the device

    system.stateVersion = "23.11";
  };

  home = {lib, myconfig, ...}: lib.mkIf (myconfig.host.name == "steamdeck") {
    roles = {
      social.enable = true;
    };

    nixicle.user = {
      enable = true;
      name = "deck";
    };

    home.stateVersion = "23.11";
  };
}
