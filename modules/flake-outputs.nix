{ inputs, lib, ... }:
let
  supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
  forAllSystems = lib.genAttrs supportedSystems;

  extendedLib = lib.extend (self: super: {
    nixicle = import ../old/lib {
      inherit inputs;
      lib = self;
    };
  });

  overlays = [
    inputs.gomod2nix.overlays.default
    inputs.nur.overlays.default
    inputs.nix-topology.overlays.default
    inputs.niri.overlays.niri
    (final: prev: {
      zjstatus = inputs.zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
    })
    (final: prev: {
      inherit (inputs) get-shit-done;
      nixicle = extendedLib.nixicle.importPackages final ../old/packages // {
        zellij-mcp = prev.callPackage ../old/packages/zellij-mcp {
          inherit inputs;
        };
      };
    })
  ];

  mkPkgs = system: import inputs.nixpkgs {
    inherit system overlays;
    config.allowUnfree = true;
  };
in
{
  flake.packages = forAllSystems (system:
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
          (inputs.import-tree.match ".*/default\\.nix" ../old/modules/nixos)
          ../old/iso/graphical
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

  flake.devShells = forAllSystems (system:
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

  flake.deploy = extendedLib.nixicle.mkDeploy {
    self = inputs.self;
    overrides = {
      framework.profiles.system.sshUser = "haseeb";
      vm.profiles.system.sshUser = "haseeb";
    };
  };

  flake.checks = builtins.mapAttrs (
    system: deploy-lib: deploy-lib.deployChecks inputs.self.deploy
  ) inputs.deploy-rs.lib;

  flake.topology =
    let
      host = inputs.self.nixosConfigurations.${builtins.head (builtins.attrNames inputs.self.nixosConfigurations)};
    in
    import inputs.nix-topology {
      inherit (host) pkgs;
      modules = [
        (import ../old/topology { inherit (host) config; })
        { inherit (inputs.self) nixosConfigurations; }
      ];
    };
}
