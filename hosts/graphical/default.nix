{delib, ...}:
delib.host {
  name = "graphical";
  rice = "catppuccin";

  myconfig = {
    hosts.graphical = {
      type = "iso";
      isIso = true;
      system = "x86_64-linux";
    };
  };

  nixos = {pkgs, lib, config, myconfig, ...}: lib.mkIf (myconfig.host.name == "graphical") {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.wireless.enable = lib.mkForce false;
    hardware.networking.enable = true;

    roles = {
      desktop.addons.gnome.enable = true;
    };

    nix.enable = true;
    services = {
      openssh.enable = true;
    };

    system = {
      locale.enable = true;
    };

    services.displayManager.autoLogin = {
      enable = true;
      user = "nixos";
    };

    users.users = {
      nixos.extraGroups = ["networkmanager"];

      # TODO: reuse existing openss config
      nixos.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuM4bCeJq0XQ1vd/iNK650Bu3wPVKQTSB0k2gsMKhdE hello@haseebmajid.dev"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGOEtfQ0znAH8QyB4Z5FzRPa9iKkBhuriEpqyfoEkiv+ haseeb.majid@imaginecurve.com"
      ];
    };

    system.stateVersion = "23.11";
  };
}
