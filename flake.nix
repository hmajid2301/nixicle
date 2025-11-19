{
  description = "Haseeb's Nix/NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    denix = {
      url = "github:yunfachi/denix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nur = {
      url = "github:nix-community/NUR";
    };

    nixos-hardware = {
      url = "github:nixos/nixos-hardware";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";
    lanzaboote.url = "github:nix-community/lanzaboote";

    nixgl.url = "github:nix-community/nixGL";
    nix-index-database.url = "github:nix-community/nix-index-database";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    nixos-anywhere = {
      url = "github:numtide/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.disko.follows = "disko";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    comma = {
      url = "github:nix-community/comma";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland

    hypr-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprcursor = {
      url = "github:hyprwm/Hyprcursor";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyprland = {
      url = "github:hyprland-community/pyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia.url = "github:caelestia-dots/shell";

    # DankMaterialShell

    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-cli = {
      url = "github:AvengeMedia/danklinux";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.dgop.follows = "dgop";
      inputs.dms-cli.follows = "dms-cli";
    };

    danksearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Homelab

    nix-topology = {
      url = "github:oddlama/nix-topology";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    authentik-nix = {
      url = "github:nix-community/authentik-nix";
    };

    # Styling

    catppuccin-obs = {
      url = "github:catppuccin/obs";
      flake = false;
    };

    stylix.url = "github:danth/stylix";
    catppuccin.url = "github:catppuccin/nix";

    # Terminal

    zjstatus = {
      url = "github:dj95/zjstatus";
    };

    # Neovim
    nixCats.url = "github:BirdeeHub/nixCats-nvim";

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
    };

    plugins-cmp-dbee = {
      url = "github:MattiasMTS/cmp-dbee";
      flake = false;
    };

    plugins-gx-nvim = {
      url = "github:chrishrb/gx.nvim";
      flake = false;
    };

    plugins-maximize-nvim = {
      url = "github:declancm/maximize.nvim";
      flake = false;
    };

    plugins-nvim-dap-view = {
      url = "github:igorlfs/nvim-dap-view";
      flake = false;
    };

    plugins-webify-nvim = {
      url = "github:pabloariasal/webify.nvim";
      flake = false;
    };

    plugins-templ-goto-definition = {
      url = "github:catgoose/templ-goto-definition";
      flake = false;
    };

    plugins-tiny-code-actions = {
      url = "github:rachartier/tiny-code-action.nvim";
      flake = false;
    };

    plugins-cmp-go-deep = {
      url = "github:samiulsami/cmp-go-deep";
      flake = false;
    };

    plugins-inline-edit = {
      url = "github:AndrewRadev/inline_edit.vim";
      flake = false;
    };

    plugins-neotest-golang = {
      url = "github:fredrikaverpil/neotest-golang";
      flake = false;
    };

    plugins-neotest = {
      url = "github:nvim-neotest/neotest";
      flake = false;
    };

    plugins-warp-nvim = {
      url = "github:y3owk1n/warp.nvim";
      flake = false;
    };

    nvim-treesitter-main = {
      url = "github:iofq/nvim-treesitter-main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    denix,
    deploy-rs,
    nix-topology,
    ...
  }: let
    # Custom library functions (replacement for snowfall-lib)
    nixicleLib = nixpkgs.lib.extend (final: prev: {
      nixicle = import ./lib/module {lib = final;};
    });

    # Helper to create configurations for each system type
    mkConfigurations = moduleSystem:
      denix.lib.configurations {
        homeManagerUser = "haseeb";
        inherit moduleSystem;
        paths =
          if moduleSystem == "nixos"
          then [./hosts ./modules/config ./modules/nixos ./rices]
          else if moduleSystem == "home"
          then [./hosts ./modules/config ./modules/home ./rices]
          else [./hosts ./modules ./rices];
        specialArgs = {
          inherit inputs;
          lib = nixicleLib;
        };
        # Add external modules based on system type
        extraModules =
          if moduleSystem == "nixos"
          then
            with inputs; [
              stylix.nixosModules.stylix
              home-manager.nixosModules.home-manager
              disko.nixosModules.disko
              lanzaboote.nixosModules.lanzaboote
              impermanence.nixosModules.impermanence
              sops-nix.nixosModules.sops
              nix-topology.nixosModules.default
              authentik-nix.nixosModules.default
            ]
          else if moduleSystem == "home"
          then
            with inputs; [
              impermanence.homeManagerModules.impermanence
              dankMaterialShell.homeModules.dankMaterialShell.default
              caelestia.homeManagerModules.default
              stylix.homeModules.stylix
              catppuccin.homeModules.catppuccin
              sops-nix.homeManagerModules.sops
            ]
          else [];
      };

    # Nixpkgs configuration
    nixpkgsConfig = {
      allowUnfree = true;
    };

    # System-specific package sets
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"];
    pkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        config = nixpkgsConfig;
        overlays = with inputs; [
          nixgl.overlay
          nur.overlays.default
          nix-topology.overlays.default
          nvim-treesitter-main.overlays.default
        ];
      });
  in {
    nixosConfigurations = mkConfigurations "nixos";
    homeConfigurations = mkConfigurations "home";

    # Overlays
    overlays = import ./overlays {inherit inputs;};

    # Packages
    packages = forAllSystems (system: import ./packages {pkgs = pkgsFor.${system};});

    # Dev shells
    devShells = forAllSystems (system: import ./shells {
      pkgs = pkgsFor.${system};
      inherit inputs;
    });

    # Deploy-rs configuration
    deploy = import ./lib/deploy {
      inherit self inputs;
      lib = nixpkgs.lib;
    };

    checks = builtins.mapAttrs (
      system: deploy-lib: deploy-lib.deployChecks self.deploy
    ) deploy-rs.lib;

    # Topology visualization
    topology = let
      host = self.nixosConfigurations.${builtins.head (builtins.attrNames self.nixosConfigurations)};
    in
      import nix-topology {
        inherit (host) pkgs;
        modules = [
          (import ./topology {inherit (host) config;})
          {inherit (self) nixosConfigurations;}
        ];
      };
  };
}
