{
  inputs,
  lib,
  config,
  ...
}:
let
  supportedSystems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  forAllSystems = lib.genAttrs supportedSystems;

  inherit ((import ../lib { inherit inputs lib; })) extendedLib;

  overlays = [
    extendedLib.nixicle.overlays.nur
    extendedLib.nixicle.overlays."nix-topology"
    extendedLib.nixicle.overlays.niri
    extendedLib.nixicle.overlays.zjstatus
    extendedLib.nixicle.overlays.nixicle
  ];

  mkPkgs =
    system:
    import inputs.nixpkgs {
      inherit system overlays;
      config.allowUnfreePredicate = extendedLib.nixicle.allowUnfreePredicate;
    };

  mkPreCommitCheck =
    system:
    let
      pkgs = mkPkgs system;
    in
    inputs.git-hooks-nix.lib.${system}.run {
      src = ../.;
      package = pkgs.prek;
      hooks = {
        gitleaks.enable = true;
        nixfmt.enable = true;
        deadnix = {
          enable = true;
          settings.edit = true;
        };
        statix = {
          enable = true;
          args = [ "fix" ];
        };
        terraform-format = {
          enable = true;
          files = "\\.(tf|tofu|tfvars)$";
        };
      };
    };
in
{
  flake-file.inputs = {
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-anywhere = {
      url = "github:numtide/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-topology = {
      url = "github:oddlama/nix-topology";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs.nixfmt.enable = true;
    };
  };

  flake = {
    packages = forAllSystems (
      system:
      let
        pkgs = mkPkgs system;
      in
      pkgs.nixicle
      // {
        iso-graphical =
          (inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = {
              inherit inputs;
              lib = extendedLib;
            };
            modules = [
              "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
              inputs.stylix.nixosModules.stylix
              inputs.home-manager.nixosModules.home-manager
              inputs.lanzaboote.nixosModules.lanzaboote
              inputs.impermanence.nixosModules.impermanence
              inputs.sops-nix.nixosModules.sops
              inputs.tangled.nixosModules.knot-rs
              inputs.tangled.nixosModules.spindle
              inputs.nixflix.nixosModules.nixflix
              inputs.niri.nixosModules.niri
              inputs.goroutinely.nixosModules.default
              ../iso/graphical
              {
                nixpkgs.hostPlatform = system;
                nixpkgs.overlays = overlays;
                isoImage.volumeID = lib.mkForce "nixicle-${
                  lib.substring 0 8 (inputs.self.lastModifiedDate or inputs.self.lastModified or "19700101")
                }";
              }
            ];
          }).config.system.build.isoImage;

        tangled-spindle-nixos-image =
          let
            imageSystem = "${lib.head (lib.splitString "-" system)}-linux";
            imagePkgs = mkPkgs imageSystem;
            spindleNixosSystem = inputs.nixpkgs.lib.nixosSystem {
              system = imageSystem;
              modules = [
                inputs.tangled.nixosModules.spindle-nixos
                (
                  {
                    config,
                    options,
                    pkgs,
                    ...
                  }:
                  let
                    microvm = inputs.tangled.inputs.microvm;
                    removeInitrdEnable =
                      path:
                      lib.updateManyAttrsByPath [
                        {
                          inherit path;
                          update = attrs: builtins.removeAttrs attrs [ "enable" ];
                        }
                      ];
                    # TODO: drop once Tangled drops this root from its blacklist;
                    # nss-cacert refuses to build with blocklist entries that the
                    # cert store no longer carries.
                    removeAbsentBlocklistRoot = lib.updateManyAttrsByPath [
                      {
                        path = [
                          "security"
                          "pki"
                          "caCertificateBlacklist"
                        ];
                        update = lib.remove "emSign ECC Root CA - G3";
                      }
                    ];
                  in
                  {
                    # TODO: drop once Tangled and MicroVM support systemd-only initrd.
                    disabledModules = [
                      "${inputs.tangled}/nix/microvm/base.nix"
                      "${microvm}/nixos-modules/microvm/optimization.nix"
                      "${microvm}/nixos-modules/microvm/mounts.nix"
                    ];
                    imports = [
                      (removeAbsentBlocklistRoot (
                        removeInitrdEnable [ "boot" "initrd" "systemd" ] (
                          import "${inputs.tangled}/nix/microvm/base.nix" { inherit config pkgs lib; }
                        )
                      ))
                      (removeInitrdEnable [ "content" "boot" "initrd" "systemd" ] (
                        import "${microvm}/nixos-modules/microvm/optimization.nix" { inherit config options lib; }
                      ))
                      (import "${microvm}/nixos-modules/microvm/mounts.nix" {
                        inherit lib;
                        config = config // {
                          boot = config.boot // {
                            initrd = config.boot.initrd // {
                              systemd = config.boot.initrd.systemd // {
                                enable = true;
                              };
                            };
                          };
                        };
                      })
                    ];
                  }
                )
                {
                  # TODO: Send upstream fix for spindle-nixos-image to fall back to
                  # `bzImage` when hostPlatform."linux-kernel".target is missing on
                  # newer nixpkgs, then drop this local workaround.
                  nixpkgs.hostPlatform = {
                    system = imageSystem;
                    "linux-kernel".target = "bzImage";
                  };
                  # Apply the same overlays as the rest of the flake.
                  nixpkgs.overlays = overlays;
                }
              ];
            };
          in
          imagePkgs.callPackage "${inputs.tangled}/nix/pkgs/spindle-nixos-image.nix" {
            nixosSystem = spindleNixosSystem;
          };
      }
    );

    apps = forAllSystems (
      system:
      let
        pkgs = mkPkgs system;
      in
      lib.mapAttrs (
        name: f:
        let
          drv = f pkgs;
        in
        {
          type = "app";
          program = "${drv}/bin/${name}";
        }
      ) config.flake-file.apps
    );

    devShells = forAllSystems (
      system:
      let
        pkgs = mkPkgs system;

        preCommitCheck = mkPreCommitCheck system;
      in
      {
        default = pkgs.mkShell {
          NIX_CONFIG = "extra-experimental-features = nix-command flakes";
          inherit (preCommitCheck) shellHook;
          packages =
            with pkgs;
            [
              inputs.nixos-anywhere.packages.${pkgs.stdenv.hostPlatform.system}.nixos-anywhere
              inputs.deploy-rs.packages.${pkgs.stdenv.hostPlatform.system}.default
              inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.default

              nh

              statix
              deadnix
              nixfmt

              sops
              ssh-to-age
              age

              git
              gnupg
              opentofu
              mc
              go-task
              gum
            ]
            ++ preCommitCheck.enabledPackages;
        };
      }
    );

    deploy = extendedLib.nixicle.mkDeploy {
      inherit (inputs) self;
      overrides = {
        vps.profiles.system = {
          user = "root";
          sshUser = "nixos";
        };
      };
    };

    checks = builtins.mapAttrs (
      system: deploy-lib:
      (deploy-lib.deployChecks inputs.self.deploy)
      // {
        pre-commit-check = mkPreCommitCheck system;
      }
    ) inputs.deploy-rs.lib;

    topology =
      let
        hosts = {
          inherit (inputs.self.nixosConfigurations) nas vps;
        };
        host = hosts.vps;
      in
      import inputs.nix-topology {
        pkgs = host.pkgs.extend inputs.nix-topology.overlays.default;
        modules = [
          (import ../topology { inherit (host) config; })
          { nixosConfigurations = hosts; }
        ];
      };
  };
}
