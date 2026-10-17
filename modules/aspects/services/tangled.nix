{ den, inputs, ... }:
{
  flake-file.inputs.fenix = {
    url = "github:nix-community/fenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake-file.inputs.tangled = {
    url = "git+https://tangled.sh/@tangled.sh/core";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.fenix.follows = "fenix";
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
        mode = "0711";
      }
      {
        directory = "/var/lib/knot";
        user = "knot";
        group = "knot";
        mode = "0750";
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
        config,
        pkgs,
        lib,
        ...
      }:
      let
        system = pkgs.stdenv.hostPlatform.system;
        ownerDid = "did:plc:reouqbpvl2kbkhvok2pwhlzg";

        # TODO: Send upstream fix for nix's musl static build to include
        # <sys/syscall.h> for SYS_close_range, then drop this local workaround.
        alpineImage = inputs.tangled.packages.${system}.spindle-alpine-image.override {
          pkgsStatic = pkgs.pkgsStatic.extend (
            _: prev:
            let
              components =
                prev.nixVersions."nixComponents_${
                  lib.replaceStrings [ "." ] [ "_" ] (lib.versions.majorMinor prev.nix.version)
                }";
            in
            {
              nixStatic =
                (components.overrideScope (
                  _: prevComponents: {
                    "nix-util" = prevComponents."nix-util".overrideAttrs (old: {
                      postPatch = (old.postPatch or "") + ''
                        substituteInPlace unix/file-descriptor.cc \
                          --replace-fail '#include <unistd.h>' '#include <unistd.h>
                        #include <sys/syscall.h>'
                      '';
                    });
                  }
                )).nix-everything;
            }
          );
        };
      in
      {
        imports = [
          inputs.tangled.nixosModules.knot-rs
          inputs.tangled.nixosModules.spindle
        ];

        sops.secrets.knot_master_key = { };
        sops.templates."knot-env".content = ''
          KNOT_MASTER_KEY=${config.sops.placeholder.knot_master_key}
        '';

        users.users.git = {
          isSystemUser = true;
          group = "git";
          home = "/home/git";
        };
        users.groups.git = { };

        system.backup.objects.knot.paths = [ config.services.tangled.knot-rs.stateDir ];

        systemd.services.knot-rs = {
          unitConfig.RequiresMountsFor = [ config.services.tangled.knot-rs.stateDir ];
          serviceConfig.ExecStartPre = lib.mkBefore [
            "+${lib.getExe' pkgs.coreutils "install"} -d -m 0750 -o ${config.services.tangled.knot-rs.user} -g ${config.services.tangled.knot-rs.group} ${lib.escapeShellArg config.services.tangled.knot-rs.settings.repo.scan_path}"
          ];
        };

        services = {
          tangled = {
            knot-rs = {
              enable = true;
              package = inputs.tangled.packages.${system}.knot-rs;
              environmentFile = config.sops.templates."knot-env".path;
              settings = {
                server = {
                  hostname = "knot.${config.nixicle.domains.root}";
                  admins = [ ownerDid ];
                  listen_addr = "127.0.0.1:5555";
                  ssh_listen_addr = "[::]:2222";
                };
                atproto.plc_directory = "https://plc.directory";
                git.object_format = "sha1";
                xrpc = {
                  trusted_proxy_header = "x-forwarded-for";
                  trusted_proxies = [
                    "127.0.0.1"
                    "::1"
                  ];
                };
              };
            };

            spindle = {
              enable = true;
              package = inputs.tangled.packages.${system}.spindle;
              server = {
                owner = ownerDid;
                hostname = "spindle.${config.nixicle.domains.root}";
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

          traefik.dynamicConfigOptions.http = lib.mkMerge [
            (lib.nixicle.mkTraefikService {
              name = "knot";
              port = 5555;
              subdomain = "knot";
              domain = config.nixicle.domains.root;
            })
            (lib.nixicle.mkTraefikService {
              name = "spindle";
              port = 6555;
              subdomain = "spindle";
              domain = config.nixicle.domains.root;
            })
          ];
        };

        # Spindle discovers microVM images by name under imageDir; mirror
        # upstream's symlink layout so workflow names stay compatible with docs.
        systemd.tmpfiles.rules = [
          "d /var/lib/spindle/images 0755 root root - -"
          "L+ /var/lib/spindle/images/nixos-x86_64 - - - - ${
            inputs.self.packages.${system}.tangled-spindle-nixos-image
          }"
          "L+ /var/lib/spindle/images/nixos - - - - /var/lib/spindle/images/nixos-x86_64"
          "L+ /var/lib/spindle/images/alpine-x86_64 - - - - ${alpineImage}"
          "L+ /var/lib/spindle/images/alpine - - - - /var/lib/spindle/images/alpine-x86_64"
        ];
      };
  };
}
