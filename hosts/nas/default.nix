{ den, inputs, lib, ... }:
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
  flake-file.inputs.nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

  den.aspects.nas = {
    includes = [
      den.aspects.performance-base
      den.aspects.server
      den.aspects.boot-secure # LUKS+TPM2 secure boot (includes den.aspects.boot)
      den.aspects.impermanence # ephemeral btrfs root, /persist for state
      den.aspects.fish
    ];

    # NAS service state that must survive the impermanence rollback.
    persist.directories = [
      "/var/lib/samba"
      "/var/lib/nfs"
    ];

    homeManager = { ... }: {
      home.stateVersion = "26.05";
    };

    nixos = { pkgs, ... }: {
      # Split into the small files recommended by the migration notes
      # (storage import, shares, health, app recovery), mirroring the
      # nijho.lt TrueNAS->NixOS migration structure.
      imports = [
        ./hardware-configuration.nix
        ./disks.nix
        ./storage.nix
        ./nfs.nix
        ./samba.nix
        ./health.nix
        inputs.nixos-facter-modules.nixosModules.facter
        { config.facter.reportPath = ./facter.json; }
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
        rsync
        tmux
        vim
        zfs
      ];

      users.mutableUsers = false;

      home-manager.users.haseeb.home.stateVersion = "26.05";

      # `media` gid 3000 matches the recovered TrueNAS ownership on
      # /mnt/main/main and the homelab datasets (fleet convention; framebox
      # uses the same gid). Members can read/write shared data.
      users.groups.media.gid = 3000;

      users.users.root.openssh.authorizedKeys.keys = authorizedKeys;

      users.users.nixos = {
        isNormalUser = true;
        uid = 1000; # matches TrueNAS NFS anonuid/anongid and share owner
        group = "users";
        extraGroups = [
          "wheel"
          "media"
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

      # Allow SSH during recovery. NFS/SMB firewall openings are declared
      # in their respective aspect files (nfs.nix / samba.nix) where the
      # services are enabled.
      networking.firewall.allowedTCPPorts = [ 22 ];

      system.stateVersion = "26.05";
    };
  };
}
