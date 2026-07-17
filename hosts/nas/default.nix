{ den, lib, pkgs, ... }:
let
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuM4bCeJq0XQ1vd/iNK650Bu3wPVKQTSB0k2gsMKhdE hello@haseebmajid.dev"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwAamg3cSHP+91grc7qmrwNoPpbxD/IMi8MhqpptuM2 hello@haseebmajid.dev"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBZsm7CzZ50x8eaUrXaMmNRE2J9qK9E9X9vFHuv04E1V hello@haseebmajid.dev"
  ];
in
{
  den.aspects.nas = {
    includes = [
      den.aspects.performance-base
      den.aspects.server
      den.aspects.boot
      den.aspects.fish
    ];

    nixos = { ... }: {
      imports = [
        ./hardware-configuration.nix
        ./disks.nix
      ];

      boot = {
        supportedFilesystems = [ "zfs" ];
        zfs.extraPools = [ ];
      };

      networking = {
        hostName = "nas";
        useDHCP = lib.mkDefault true;

        # Stable hostid is required for clean ZFS imports on Linux.
        # If you already know the desired value from the old environment,
        # replace this before the first writable import.
        hostId = "6e617300";
      };

      environment.systemPackages = with pkgs; [
        git
        hdparm
        jq
        lsof
        nvme-cli
        rsync
        smartmontools
        tmux
        vim
        zfs
      ];

      users.mutableUsers = false;

      users.users.root.openssh.authorizedKeys.keys = authorizedKeys;

      users.users.nixos = {
        isNormalUser = true;
        group = "users";
        extraGroups = [
          "wheel"
        ];
        initialPassword = "changeme";
        openssh.authorizedKeys.keys = authorizedKeys;
        shell = pkgs.fish;
      };

      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "prohibit-password";
        };
      };

      security.sudo = {
        execWheelOnly = true;
        wheelNeedsPassword = false;
      };

      services.zfs = {
        autoScrub.enable = false;
        trim.enable = false;
      };

      # Recovery-first defaults:
      # - keep imports/manual unlocks explicit
      # - do not auto-declare production pools yet
      # - only the boot disk belongs in disko
      fileSystems."/mnt/recovery" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [
          "mode=0755"
          "size=2G"
        ];
      };

      networking.firewall.allowedTCPPorts = [ 22 ];

      system.stateVersion = "26.05";
    };
  };
}
