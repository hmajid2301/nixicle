{ inputs, lib, config, ... }:
let
  supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
  forAllSystems = lib.genAttrs supportedSystems;

  extendedLib = lib.extend (self: super: {
    nixicle = import ../lib {
      inherit inputs;
      lib = self;
    };
  });

  overlays = [
    inputs.nur.overlays.default
    inputs.nix-topology.overlays.default
    inputs.niri.overlays.niri
    (final: prev: {
      zjstatus = inputs.zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
    })
    (final: prev: {
      inherit (inputs) get-shit-done;
      nixicle = extendedLib.nixicle.importPackages final ../packages // {
        zellij-mcp = prev.callPackage ../packages/zellij-mcp {
          inherit inputs;
        };
      } // {
        gsesh = inputs.gsesh.packages.${prev.stdenv.hostPlatform.system}.default;
      };
    })
  ];

  mkPkgs = system: import inputs.nixpkgs {
    inherit system overlays;
    config.allowUnfree = true;
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
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
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

  flake = {
    packages = forAllSystems (system:
      let pkgs = mkPkgs system;
      in pkgs.nixicle // {
        iso-graphical = inputs.nixos-generators.nixosGenerate {
          inherit system;
          specialArgs = {
            inherit inputs;
            lib = extendedLib;
          };
          modules = [
            inputs.stylix.nixosModules.stylix
            inputs.home-manager.nixosModules.home-manager
            inputs.lanzaboote.nixosModules.lanzaboote
            inputs.impermanence.nixosModules.impermanence
            inputs.sops-nix.nixosModules.sops
            inputs.authentik-nix.nixosModules.default
            inputs.tangled.nixosModules.knot
            inputs.tangled.nixosModules.spindle
            inputs.nixflix.nixosModules.nixflix
            inputs.niri.nixosModules.niri
            inputs.goroutinely.nixosModules.default
            ../hosts/iso/graphical
            {
              nixpkgs.hostPlatform = system;
              nixpkgs.overlays = overlays;
              image.baseName = lib.mkForce "nixicle-graphical";
              isoImage.volumeID = lib.mkForce "nixicle-${
                lib.substring 0 8 (inputs.self.lastModifiedDate or inputs.self.lastModified or "19700101")
              }";
            }
          ];
          format = "iso";
        };
      }
    );

    apps = forAllSystems (system:
      let pkgs = mkPkgs system;
      in lib.mapAttrs (name: f:
        let drv = f pkgs;
        in { type = "app"; program = "${drv}/bin/${name}"; }
      ) config.flake-file.apps
    );

    devShells = forAllSystems (system:
    let pkgs = mkPkgs system;
    in {
      default = pkgs.mkShell {
        NIX_CONFIG = "extra-experimental-features = nix-command flakes";
        packages = with pkgs; [
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
          statix
          deadnix
          alejandra
          inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.default
          git
          sops
          ssh-to-age
          gnupg
          age
          opentofu
          mc
          go-task
          gum
        ];
      };
    }
  );

    deploy = extendedLib.nixicle.mkDeploy {
      inherit (inputs) self;
      overrides = {
        framework.profiles.system.sshUser = "haseeb";
        vm.profiles.system.sshUser = "haseeb";
      };
    };

    checks = builtins.mapAttrs (
      system: deploy-lib: deploy-lib.deployChecks inputs.self.deploy
    ) inputs.deploy-rs.lib;

    topology =
      let
        host = inputs.self.nixosConfigurations.${builtins.head (builtins.attrNames inputs.self.nixosConfigurations)};
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
