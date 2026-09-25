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
    # nixos-generators is deprecated; using upstream iso-image.nix directly
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
              inputs.tangled.nixosModules.knot
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

              bun

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
        host =
          inputs.self.nixosConfigurations.${builtins.head (builtins.attrNames inputs.self.nixosConfigurations)};
      in
      import inputs.nix-topology {
        inherit (host) pkgs;
        modules = [
          (import ../topology { inherit (host) config; })
          { inherit (inputs.self) nixosConfigurations; }
        ];
      };
  };
}
