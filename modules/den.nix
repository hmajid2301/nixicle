# Den entry point — wires the den framework into the module system and declares
# all hosts and users. Host-specific aspects live in modules/aspects/hosts/,
# user-specific aspects in modules/aspects/users/.
{ inputs, den, lib, ... }:
let
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
      nixicle = lib.nixicle.importPackages final (../packages) // {
        zellij-mcp = prev.callPackage (../packages/zellij-mcp) { inherit inputs; };
      };
    })
  ];

  # NixOS modules shared across all nixos-class hosts
  baseNixosModules = [
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
    inputs.disko.nixosModules.disko
    inputs.nix-topology.nixosModules.default
    (inputs.import-tree.match ".*/default\\.nix" ./nixos)
  ];

  # Home-manager modules shared across all users
  commonHomeModules = [
    inputs.dankMaterialShell.homeModules.dank-material-shell
    inputs.noctalia.homeModules.default
    inputs.sops-nix.homeManagerModules.sops
    inputs.stylix.homeModules.stylix
    inputs.catppuccin.homeModules.catppuccin
    inputs.nix-index-database.homeModules.nix-index
    inputs.pam-shim.homeModules.default
    inputs.niri.homeModules.niri
    inputs.niri.homeModules.stylix
    (inputs.import-tree.match ".*/default\\.nix" ./home)
  ];
in
{
  imports = [ inputs.den.flakeModule ];

  # ---------------------------------------------------------------------------
  # Global schema defaults
  # ---------------------------------------------------------------------------

  # All users get homeManager class by default
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  # Override per-host instantiation to inject pkgs, specialArgs, and our
  # existing NixOS module list into den's host builder.
  den.schema.host = { host, lib, ... }: {
    config.instantiate = lib.mkDefault (
      args:
      let
        hostDir = ../hosts + "/${host.hostName}";
        hostHardware = hostDir + "/hardware-configuration.nix";
        hostDisks = hostDir + "/disks.nix";
        hostModules = lib.optional (builtins.pathExists hostHardware) hostHardware
          ++ lib.optional (builtins.pathExists hostDisks) hostDisks;
      in
      inputs.nixpkgs.lib.nixosSystem (args // {
        pkgs = import inputs.nixpkgs {
          system = host.system;
          inherit overlays;
          config.allowUnfree = true;
        };
        specialArgs = (args.specialArgs or { }) // { inherit inputs lib; };
        modules = baseNixosModules ++ hostModules ++ (args.modules or [ ]);
      })
    );
  };

  # Override home instantiation to inject pkgs, extraSpecialArgs, and our
  # existing home-manager module list.
  den.schema.home = { home, lib, ... }: {
    config.instantiate = lib.mkDefault (
      args: inputs.home-manager.lib.homeManagerConfiguration (args // {
        pkgs = import inputs.nixpkgs {
          system = home.system;
          inherit overlays;
          config.allowUnfree = true;
        };
        extraSpecialArgs = (args.extraSpecialArgs or { }) // {
          inherit inputs lib;
          host = home.hostName or home.name;
        };
        modules = commonHomeModules ++ (args.modules or [ ]);
      })
    );
  };

  # ---------------------------------------------------------------------------
  # Global aspect defaults applied to every host, user, and home
  # ---------------------------------------------------------------------------

  den.default.includes = [
    den.provides.define-user   # create users.users.<name> + home.username/homeDirectory
    den.provides.hostname      # set networking.hostName from den.hosts.<name>.hostName
  ];

  den.default = {
    nixos.system.stateVersion = lib.mkDefault "24.05";
    homeManager.home.stateVersion = lib.mkDefault "24.05";
  };

  # ---------------------------------------------------------------------------
  # Host declarations
  # Each host entry auto-creates den.aspects.<hostname> with a nixos class.
  # The per-host aspects are extended in modules/aspects/hosts/<hostname>.nix
  # ---------------------------------------------------------------------------

  den.hosts.x86_64-linux = {
    framework.users.haseeb = { };
    vm.users.haseeb = { };
    framebox.users.haseeb = { };
    workstation.users.haseeb = { };
    vps = { }; # server only — no desktop user
  };

  # ---------------------------------------------------------------------------
  # Standalone home configurations (non-NixOS machines)
  # ---------------------------------------------------------------------------

  den.homes.x86_64-linux = {
    "haseebmajid@dell" = {
      userName = "haseebmajid";
    };
  };
}
