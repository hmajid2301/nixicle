{
  den,
  inputs,
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
      den.aspects.nixflix
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

    nixos =
      {
        lib,
        pkgs,
        ...
      }:
      {
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
          extraGroups = [
            "wheel"
            "media"
            "docker"
          ];
          uid = 1000;
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

          hostId = "5e0a6087";
          firewall.allowedTCPPorts = [ 22 ];
        };

        boot = {
          supportedFilesystems = [ "zfs" ];
          zfs = {
            extraPools = [ "main" ];

            forceImportRoot = false;
            forceImportAll = false;
          };
        };

        hardware.graphics = {
          enable = true;
          extraPackages = [ pkgs.intel-media-driver ];
        };

        virtualisation.docker = {
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

        nixflix = {
          globals.gids = {
            media = 3000;
            autobrr = 188;
            cross-seed = 183;
            jellyfin = 146;
            prowlarr = 287;
            recyclarr = 269;
            seerr = 250;
          };
          mediaDir = lib.mkForce "/mnt/main/main-encrypted/homelab/media";
          stateDir = lib.mkForce "/persist/nixflix";
          downloadsDir = lib.mkForce "/persist/nixflix/downloads";
          maintainerr.enable = true;
        };

        environment.etc = {
          "tmpfiles.d/10-nixflix.conf" = lib.mkForce {
            text = ''
              d /persist/nixflix 0775 root media - -
              d /persist/nixflix/downloads 0775 root media - -
            '';
          };
          "tmpfiles.d/10-sonarr.conf" = lib.mkForce {
            text = "d /persist/nixflix/sonarr 0775 root media - -\n";
          };
          "tmpfiles.d/10-radarr.conf" = lib.mkForce {
            text = "d /persist/nixflix/radarr 0775 root media - -\n";
          };
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

        users.users.haseeb.extraGroups = [ "docker" ];

        home-manager.users.haseeb.home.stateVersion = "26.05";
        system.stateVersion = "26.05";
      };
  };
}
