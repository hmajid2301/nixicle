{
  den,
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

  den.aspects.nas = {
    includes = [
      den.aspects.performance-base
      den.aspects.server
      den.aspects.server-admin
      den.aspects.boot-secure # LUKS+TPM2 secure boot (includes den.aspects.boot)
      den.aspects.impermanence # ephemeral btrfs root, /persist for state
      den.aspects.attic-cache
      den.aspects.backup-restic
      den.aspects.fish
      den.aspects.tailscale
      den.aspects.jellyfin
      den.aspects.otel-collector-forwarder
    ];

    # NAS service state that must survive the impermanence rollback.
    persist.directories = [
      "/var/lib/samba"
      "/var/lib/nfs"
      "/var/lib/docker" # stash image + container state
    ];

    homeManager = _: {
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
        ./backup.nix
        inputs.nixos-facter-modules.nixosModules.facter
        { config.facter.reportPath = ./facter.json; }
      ];

      sops.defaultSopsFile = ./secrets.yaml;

      nixicle.serverAdmin = {
        enable = true;
        # `media` gid 3000 matches the recovered TrueNAS ownership on
        # /mnt/main/main and the homelab datasets (fleet convention; framebox
        # uses the same gid). Members can read/write shared data.
        extraGroups = [
          "wheel"
          "media"
        ];
        uid = 1000; # matches TrueNAS NFS anonuid/anongid and share owner
        mediaGid = 3000;
        shell = pkgs.fish;
        sudo = {
          execWheelOnly = true;
          wheelNeedsPassword = false;
        };
      };

      networking = {
        hostName = "nas";
        useDHCP = lib.mkDefault true;

        # Stable hostid is required for clean ZFS imports on Linux.
        # Observed from `zdb -e -C main`: hostid decimal 1577738375 == 5e0a6087.
        hostId = "5e0a6087";
        firewall.allowedTCPPorts = [ 22 ];
      };

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

      virtualisation.docker = {
        # Docker for the Stash compose stack. /var/lib/docker is persisted
        # (see persist.directories) so the pulled image + container survive
        # the impermanence rollback. The compose `restart: unless-stopped`
        # policy auto-starts the container when the daemon starts at boot.
        enable = true;
        enableOnBoot = true;
      };

      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "prohibit-password";
        };
      };

      services.zfs = {
        autoScrub.enable = false;
        trim.enable = false;
      };

      environment.systemPackages = with pkgs; [
        docker-compose
        git
        hdparm
        jq
        lsof
        rsync
        tmux
        vim
        zfs
      ];

      home-manager.users.haseeb.home.stateVersion = "26.05";
      system.stateVersion = "26.05";
    };
  };
}
