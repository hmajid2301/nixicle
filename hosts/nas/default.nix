{ den, lib, ... }:
let
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuM4bCeJq0XQ1vd/iNK650Bu3wPVKQTSB0k2gsMKhdE hello@haseebmajid.dev"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwAamg3cSHP+91grc7qmrwNoPpbxD/IMi8MhqpptuM2 hello@haseebmajid.dev"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBZsm7CzZ50x8eaUrXaMmNRE2J9qK9E9X9vFHuv04E1V hello@haseebmajid.dev"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLrECFz5PQ5D2+QXomsLK9HcZhHzcBUIDGkiI94c6Ux hello@haseebmajid.dev"
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

    homeManager = { ... }: {
      home.stateVersion = "26.05";
    };

    nixos = { pkgs, ... }: {
      imports = [
        ./hardware-configuration.nix
        ./disks.nix
      ];

      boot = {
        supportedFilesystems = [ "zfs" ];
        zfs = {
          # Import the preserved TrueNAS data pool by name after NixOS boots.
          # Production data-pool disks must never appear in hosts/nas/disks.nix.
          extraPools = [ "main" ];

          # Avoid automatic force-import behaviour. The observed pool hostid is set
          # below so normal imports should not require -f after cutover.
          forceImportRoot = false;
          forceImportAll = false;
        };
      };

      networking = {
        hostName = "nas";
        useDHCP = lib.mkDefault true;

        # Stable hostid is required for clean ZFS imports on Linux.
        # Observed from `zdb -e -C main`: hostid decimal 1577738375 == 5e0a6087.
        hostId = "5e0a6087";
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

      home-manager.users.haseeb.home.stateVersion = "26.05";

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
      # - only the boot disk belongs in disko
      # - production data pools are imported by name
      # - encrypted datasets remain manual until the first boot path is proven
      fileSystems."/mnt/recovery" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [
          "mode=0755"
          "size=2G"
        ];
      };

      systemd.tmpfiles.rules = [
        # Preserve the old TrueNAS path layout during first recovery.
        # The important recovered host-path data should remain reachable under this tree.
        "d /mnt/main 0755 root root -"
        "d /mnt/main/main 0755 root root -"
        "d /mnt/main/main/Data 0755 root root -"
        "d /mnt/.ix-apps 0755 root root -"
        "d /mnt/.ix-apps/app_mounts 0755 root root -"
        "d /mnt/.ix-apps/app_configs 0755 root root -"
      ];

      networking.firewall.allowedTCPPorts = [ 22 ];

      system.stateVersion = "26.05";
    };
  };
}
