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

  extendedLib = lib.extend (
    self: _super: {
      nixicle = import ../lib {
        inherit inputs;
        lib = self;
      };
    }
  );

  overlays = [
    inputs.nur.overlays.default
    inputs.nix-topology.overlays.default
    inputs.niri.overlays.niri
    (_final: prev: {
      zjstatus = inputs.zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
    })
    (final: _prev: {
      nixicle = extendedLib.nixicle.importPackages final ../packages;
      # Unwrap deprecated `stdenv.isLinux`/`isDarwin` aliases (wrapped in
      # `lib.warn`) so accessors don't spam evaluation warnings. Cover the
      # stdenv variants that downstream modules (e.g. microvm) reach through.
      stdenv = _prev.stdenv // {
        isLinux = _prev.stdenv.hostPlatform.isLinux;
        isDarwin = _prev.stdenv.hostPlatform.isDarwin;
      };
      buildPackages = _prev.buildPackages // {
        stdenv = _prev.buildPackages.stdenv // {
          isLinux = _prev.buildPackages.stdenv.hostPlatform.isLinux;
          isDarwin = _prev.buildPackages.stdenv.hostPlatform.isDarwin;
        };
      };
      pkgsBuildBuild = _prev.pkgsBuildBuild // {
        stdenv = _prev.pkgsBuildBuild.stdenv // {
          isLinux = _prev.pkgsBuildBuild.stdenv.hostPlatform.isLinux;
          isDarwin = _prev.pkgsBuildBuild.stdenv.hostPlatform.isDarwin;
        };
      };
      pkgsBuildHost = _prev.pkgsBuildHost // {
        stdenv = _prev.pkgsBuildHost.stdenv // {
          isLinux = _prev.pkgsBuildHost.stdenv.hostPlatform.isLinux;
          isDarwin = _prev.pkgsBuildHost.stdenv.hostPlatform.isDarwin;
        };
      };
      pkgsHostHost = _prev.pkgsHostHost // {
        stdenv = _prev.pkgsHostHost.stdenv // {
          isLinux = _prev.pkgsHostHost.stdenv.hostPlatform.isLinux;
          isDarwin = _prev.pkgsHostHost.stdenv.hostPlatform.isDarwin;
        };
      };
      pkgsHostTarget = _prev.pkgsHostTarget // {
        stdenv = _prev.pkgsHostTarget.stdenv // {
          isLinux = _prev.pkgsHostTarget.stdenv.hostPlatform.isLinux;
          isDarwin = _prev.pkgsHostTarget.stdenv.hostPlatform.isDarwin;
        };
      };
    })
  ];

  mkPkgs =
    system:
    import inputs.nixpkgs {
      inherit system overlays;
      config = {
        allowUnfree = true;
      };
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
      };
    };
in
{
  flake-file.inputs = {
    comma = {
      url = "github:nix-community/comma";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

  flake = {
    formatter = forAllSystems (
      system:
      let
        pkgs = mkPkgs system;
        config = (mkPreCommitCheck system).config;
      in
      pkgs.writeShellScriptBin "pre-commit-run" ''
        ${pkgs.lib.getExe config.package} run --all-files --config ${config.configFile}
      ''
    );

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
                  # Apply the same overlays as the rest of the flake so the
                  # deprecated `stdenv.isLinux`/`isDarwin` alias shim is unwrapped.
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
      in
      let
        preCommitCheck = mkPreCommitCheck system;
      in
      {
        default = pkgs.mkShell {
          NIX_CONFIG = "extra-experimental-features = nix-command flakes";
          shellHook = preCommitCheck.shellHook;
          packages =
            with pkgs;
            [
              (pkgs.nh.override {
                nix-output-monitor = pkgs.nix-output-monitor.overrideAttrs (old: {
                  postPatch = old.postPatch or "" + ''
                    substituteInPlace lib/NOM/Print.hs \
                      --replace 'down = "↓"' 'down = "\xf072e"' \
                      --replace 'up = "↑"' 'up = "\xf0737"' \
                      --replace 'clock = "⏱"' 'clock = "\xf520"' \
                      --replace 'running = "⏵"' 'running = "\xf04b"' \
                      --replace 'done = "✔"' 'done = "\xf00c"' \
                      --replace 'todo = "⏸"' 'todo = "\xf04d"' \
                      --replace 'warning = "⚠"' 'warning = "\xf071"' \
                      --replace 'average = "∅"' 'average = "\xf1da"' \
                      --replace 'bigsum = "∑"' 'bigsum = "\xf04a0"'
                  '';
                });
              })
              inputs.nixos-anywhere.packages.${pkgs.stdenv.hostPlatform.system}.nixos-anywhere
              inputs.deploy-rs.packages.${pkgs.stdenv.hostPlatform.system}.default
              inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.default

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
        framework.profiles.system.sshUser = "haseeb";
        vm.profiles.system.sshUser = "haseeb";
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
