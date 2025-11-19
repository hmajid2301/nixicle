{delib, inputs, ...}:
delib.host {
  name = "framework";

  rice = "catppuccin";

  myconfig = {
    hosts.framework = {
      type = "desktop";
      isDesktop = true;
      system = "x86_64-linux";
    };
  };

  nixos = {pkgs, lib, myconfig, ...}: lib.mkIf (myconfig.host.name == "framework") {
    imports = [
      ./hardware-configuration.nix
      ./disks.nix.helper
      inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    ];

    environment.systemPackages = with pkgs; [
      inputs.caelestia.packages.${pkgs.system}.default
      inputs.caelestia.inputs.caelestia-cli.packages.${pkgs.system}.default
    ];

    services = {
      virtualisation.kvm.enable = true;
      virtualisation.docker.enable = true;
    };

    roles = {
      gaming.enable = true;
      desktop = {
        enable = true;
        addons = {
          hyprland.enable = true;
        };
      };
    };

    networking.hostName = "framework";

    boot = {
      kernelParams = [
        "resume_offset=533760"
      ];
      supportedFilesystems = lib.mkForce [ "btrfs" ];
      kernelPackages = pkgs.linuxPackages_latest;
      resumeDevice = "/dev/disk/by-label/nixos";
    };

    system.stateVersion = "23.11";
  };

  home = {pkgs, lib, myconfig, ...}: lib.mkIf (myconfig.host.name == "framework") {
    desktops = {
      hyprland = {
        enable = true;
        execOnceExtras = [
          "${pkgs.trayscale}/bin/trayscale"
          "${pkgs.networkmanagerapplet}/bin/nm-applet"
          "${pkgs.blueman}/bin/blueman-applet"
        ];
      };
    };

    home.packages = with pkgs; [
      nwg-displays
    ];

    roles = {
      desktop.enable = true;
      development.enable = true;
      social.enable = true;
      video.enable = true;
    };

    nixicle.user = {
      enable = true;
      name = "haseeb";
    };

    home.stateVersion = "23.11";
  };
}
