{
  description = "My Nix Config";

  nixConfig = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://cache.nixos.org/"
    ];

    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    home-manager.url = "github:nix-community/home-manager";

    disko.url = "github:nix-community/disko";
    hardware.url = "github:nixos/nixos-hardware";
    sops-nix.url = "github:mic92/sops-nix";
    impermanence.url = "github:nix-community/impermanence";
    lanzaboote.url = "github:nix-community/lanzaboote";

    hyprland.url = "github:hyprwm/Hyprland";
    hypr-contrib.url = "github:hyprwm/contrib";
    nixgl.url = "github:nix-community/nixGL";
    nix-colors.url = "github:misterio77/nix-colors";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nixvim.url = "github:pta2002/nixvim";
    nixneovimplugins.url = "github:jooooscha/nixpkgs-vim-extra-plugins";

    comma.url = "github:nix-community/comma";
    attic.url = "github:zhaofengli/attic";
    nwg-displays.url = "github:nwg-piotr/nwg-displays/master";

    grub-theme = {
      url = "github:catppuccin/grub";
      flake = false;
    };

    fufexan.url = "github:fufexan/dotfiles";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    gross = {
      url = "github:fufexan/gross";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    colmena.url = "github:zhaofengli/colmena";
    kubenix.url = "github:hall/kubenix";
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , colmena
    , ...
    } @ inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib // home-manager.lib;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = f: lib.genAttrs systems (sys: f pkgsFor.${sys});
      pkgsFor = nixpkgs.legacyPackages;
    in
    {
      inherit lib;
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;
      overlays = import ./overlays { inherit inputs outputs; };
      packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
      devShells = forEachSystem (pkgs: import ./shell.nix { inherit pkgs inputs; });

      nixosConfigurations = {
        iso = lib.nixosSystem {
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
            "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
            ./hosts/iso/configuration.nix
          ];
          specialArgs = { inherit inputs outputs; };
        };

        # Desktops
        mesmer = lib.nixosSystem {
          modules = [ ./hosts/mesmer/configuration.nix ];
          specialArgs = { inherit inputs outputs; };
        };

        # Laptops
        framework = lib.nixosSystem {
          modules = [ ./hosts/framework/configuration.nix ];
          specialArgs = { inherit inputs outputs; };
        };

        # VMs
        staging = lib.nixosSystem {
          modules = [ ./hosts/staging/configuration.nix ];
          specialArgs = { inherit inputs outputs; };
        };
      };

      homeConfigurations = {
        # Desktops
        mesmer = lib.homeManagerConfiguration {
          modules = [ ./hosts/mesmer/home.nix ];
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
        };

        # Laptops
        framework = lib.homeManagerConfiguration {
          modules = [ ./hosts/framework/home.nix ];
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
        };

        curve = lib.homeManagerConfiguration {
          modules = [ ./hosts/curve/home.nix ];
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
        };

        # VMs
        staging = lib.homeManagerConfiguration {
          modules = [ ./hosts/staging/home.nix ];
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
        };
      };

      colmena = {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
          };
          specialArgs = inputs;
        };

        defaults = { pkgs, ... }: {
          imports = [
            inputs.hardware.nixosModules.raspberry-pi-4
            inputs.sops-nix.nixosModules.sops
            ./hosts/rpis/common.nix
          ];
        };

        strawberry = {
          imports = [
            ./hosts/rpis/strawberry.nix
          ];

          nixpkgs.system = "aarch64-linux";
          deployment = {
            buildOnTarget = true;
            targetHost = "strawberry";
            targetUser = "strawberry";
            tags = [ "rpi" ];
          };
        };

        # TODO: fix SSD issues
        orange = {
          imports = [
            ./hosts/rpis/orange.nix
          ];

          nixpkgs.system = "aarch64-linux";
          deployment = {
            buildOnTarget = true;
            targetHost = "orange";
            targetUser = "orange";
            tags = [ "infra" "rpi" ];
          };
        };

        guava = {
          imports = [
            ./hosts/rpis/guava.nix
          ];

          nixpkgs.system = "aarch64-linux";
          deployment = {
            buildOnTarget = true;
            targetHost = "guava";
            targetUser = "guava";
            tags = [ "rpi" ];
          };
        };

        mango = {
          imports = [
            ./hosts/rpis/mango.nix
          ];

          nixpkgs.system = "aarch64-linux";
          deployment = {
            targetHost = "mango.local";
            targetUser = "mango";
            tags = [ "infra" "rpi" ];
          };
        };
      };
    };
}
