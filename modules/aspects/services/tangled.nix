{ den, inputs, ... }:
{
  flake-file.inputs.tangled = {
    url = "git+https://tangled.sh/@tangled.sh/core";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.tangled = {
    includes = [
      den.aspects.docker
      den.aspects.nixery
    ];

    persist.directories = [
      {
        directory = "/home/git";
        user = "git";
        group = "git";
        # Secure-mode git subprocesses run as per-owner virtual UIDs outside the
        # git group; they need traverse on the home dir, but not list/read.
        mode = "0711";
      }
      {
        directory = "/var/lib/spindle";
        user = "root";
        group = "root";
        mode = "0755";
      }
    ];

    nixos =
      {
        pkgs,
        lib,
        ...
      }:
      let
        system = pkgs.stdenv.hostPlatform.system;
        ownerDid = "did:plc:reouqbpvl2kbkhvok2pwhlzg";
      in
      {
        imports = [
          inputs.tangled.nixosModules.knot
          inputs.tangled.nixosModules.spindle
        ];

        services.tangled = {
          knot = {
            enable = true;
            package = inputs.tangled.packages.${system}.knot;
            openFirewall = false;
            server = {
              owner = ownerDid;
              hostname = "knot.haseebmajid.dev";
              listenAddr = "127.0.0.1:5555";
              internalListenAddr = "127.0.0.1:5444";
              secureMode = true;
            };
          };

          spindle = {
            enable = true;
            package = inputs.tangled.packages.${system}.spindle;
            server = {
              owner = ownerDid;
              hostname = "spindle.haseebmajid.dev";
              listenAddr = "127.0.0.1:6555";
              maxJobCount = 1;
              # Use sqlite for first VPS bring-up. The OpenBao backend expects an
              # authenticated Bao proxy/agent; add that once AppRole/token flow is
              # declared.
              secrets.provider = "sqlite";
            };
            pipelines = {
              nixery.nixery = "localhost:8091";
              microvm = {
                enableKVM = true;
                # The default NixOS image declares 4GiB/2vCPU/24GiB; cap totals to
                # one full guest so the 8GiB VPS keeps enough headroom for host
                # services instead of racing the OOM killer.
                limits = {
                  total = {
                    memoryMiB = 5120;
                    vcpus = 4;
                    diskMiB = 32768;
                  };
                  workflow = {
                    memoryMiB = 4096;
                    vcpus = 2;
                    diskMiB = 24576;
                  };
                };
                cgroup = {
                  enable = true;
                  pidsMax = 4096;
                  supervisorMinMiB = 512;
                };
              };
            };
          };
        };

        # Spindle discovers microVM images by name under imageDir; mirror
        # upstream's symlink layout so workflow names stay compatible with docs.
        systemd.tmpfiles.rules = [
          "d /var/lib/spindle/images 0755 root root - -"
          "L+ /var/lib/spindle/images/nixos-x86_64 - - - - ${inputs.tangled.packages.${system}.spindle-nixos-image}"
          "L+ /var/lib/spindle/images/nixos - - - - /var/lib/spindle/images/nixos-x86_64"
          "L+ /var/lib/spindle/images/alpine-x86_64 - - - - ${inputs.tangled.packages.${system}.spindle-alpine-image}"
          "L+ /var/lib/spindle/images/alpine - - - - /var/lib/spindle/images/alpine-x86_64"
        ];

        system.activationScripts.tangled-git-home-permissions = {
          deps = [
            "users"
            "groups"
          ];
          text = ''
            chown git:git /home/git
            chmod 0711 /home/git
          '';
        };

        services.traefik.dynamicConfigOptions.http = lib.mkMerge [
          (lib.nixicle.mkTraefikService {
            name = "knot";
            port = 5555;
            subdomain = "knot";
            domain = "haseebmajid.dev";
          })
          (lib.nixicle.mkTraefikService {
            name = "spindle";
            port = 6555;
            subdomain = "spindle";
            domain = "haseebmajid.dev";
          })
        ];

        # Avoid replacing hardening-vps' admin SSH allowlist and locking out nixos.
        services.openssh.settings.AllowUsers = lib.mkAfter [ "git" ];
        services.openssh.extraConfig = ''
          Match User git
              PermitTTY no
        '';
      };
  };
}
