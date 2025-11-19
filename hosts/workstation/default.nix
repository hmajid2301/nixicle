{delib, inputs, ...}:
delib.host {
  name = "workstation";
  rice = "catppuccin";

  myconfig = {
    hosts.workstation = {
      type = "desktop";
      isDesktop = true;
      system = "x86_64-linux";
    };
  };

  nixos = {pkgs, lib, myconfig, ...}: lib.mkIf (myconfig.host.name == "workstation") {
    imports = [
      ./hardware-configuration.nix
      ./disks.nix.helper
      inputs.nixos-facter-modules.nixosModules.facter
      { config.facter.reportPath = ./facter.json; }
    ];

    environment.pathsToLink = [ "/share/fish" ];

    system.boot.plymouth = lib.mkForce false;

    # TODO: when merged in: https://github.com/systemd/systemd/issues/34304
    systemd.package = pkgs.systemd.overrideAttrs (old: {
      patches = old.patches ++ [
        (pkgs.fetchurl {
          url = "https://github.com/wrvsrx/systemd/compare/tag_fix-hibernate-resume%5E...tag_fix-hibernate-resume.patch";
          hash = "sha256-Z784xysVUOYXCoTYJDRb3ppGiR8CgwY5CNV8jJSLOXU=";
        })
      ];
    });

    hardware.nixicle.ddcci.enable = true;

    users.users.haseeb.extraGroups = [ "i2c" ];

    # TODO: Look into enabling podman again in the future
    services = {
      virtualisation.kvm.enable = true;
      virtualisation.docker.enable = true;
      virtualisation.podman.enable = lib.mkForce false;
      hardware.openrgb.enable = true;
    };

    roles = {
      gaming.enable = true;
      desktop = {
        enable = true;
        addons = {
          hyprland.enable = true;
          gnome.enable = true;
        };
      };
    };

    # TODO: move this to a module
    programs.wireshark.enable = true;

    networking.useNetworkd = lib.mkForce false;
    systemd.network.enable = lib.mkForce false;

    boot = {
      kernelParams = [ "resume_offset=533760" ];
      blacklistedKernelModules = [
        "ath12k_pci"
        "ath12k"
      ];

      kernelPackages = pkgs.linuxPackages_latest;
      resumeDevice = "/dev/disk/by-label/nixos";
    };

    system.stateVersion = "23.11";
  };

  home = {pkgs, lib, myconfig, ...}: lib.mkIf (myconfig.host.name == "workstation") {
    cli.tools.git.allowedSigners = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev";

    desktops = {
      hyprland = {
        enable = true;
        execOnceExtras = [ "${pkgs.trayscale}/bin/trayscale" ];
      };
      gnome = {
        enable = true;
      };
    };

    roles = {
      desktop.enable = true;
      social.enable = true;
      gaming.enable = true;
      video.enable = true;
    };

    nixicle.user = {
      enable = true;
      name = "haseeb";
    };

    home.stateVersion = "23.11";
  };
}
