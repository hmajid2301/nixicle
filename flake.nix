{
  description = "Haseeb's Nix/NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
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

  outputs =
    inputs@{ self, nixpkgs, home-manager, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Custom lib with recursive import helpers
      nixicleLib = import ./lib { lib = nixpkgs.lib; inherit inputs; };

      # Extended lib with nixicle namespace
      lib = nixpkgs.lib.extend (final: prev: {
        nixicle = nixicleLib;
      });

      # Overlays
      overlays = [
        inputs.nixgl.overlay
        inputs.nur.overlays.default
        inputs.nix-topology.overlays.default
        inputs.nvim-treesitter-main.overlays.default
        # Custom overlays
        (final: prev: {
          zjstatus = inputs.zjstatus.packages.${prev.system}.default;
        })
        # Custom packages overlay - auto-import all packages
        (final: prev: {
          nixicle = nixicleLib.importPackages final ./packages;
        })
      ];

      # Create pkgs for a given system
      mkPkgs = system:
        import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };

      # Common NixOS modules
      commonNixosModules = [
        inputs.stylix.nixosModules.stylix
        home-manager.nixosModules.home-manager
        inputs.disko.nixosModules.disko
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.impermanence.nixosModules.impermanence
        inputs.sops-nix.nixosModules.sops
        inputs.nix-topology.nixosModules.default
        inputs.authentik-nix.nixosModules.default
      ] 
      # Auto-import all custom NixOS modules recursively
      ++ (nixicleLib.importModulesRecursive ./modules/nixos);

      # Common home-manager modules
      commonHomeModules = [
        inputs.impermanence.nixosModules.home-manager.impermanence
        inputs.dankMaterialShell.homeModules.dankMaterialShell.default
        inputs.caelestia.homeManagerModules.default
        inputs.sops-nix.homeManagerModules.sops
        inputs.stylix.homeModules.stylix
        inputs.catppuccin.homeModules.catppuccin
        inputs.nix-index-database.homeModules.nix-index
      ]
      # Auto-import all custom home modules recursively
      ++ (nixicleLib.importModulesRecursive ./modules/home);

      # Helper to create a NixOS system
      mkSystem =
        { hostname
        , system ? "x86_64-linux"
        , extraModules ? [ ]
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          pkgs = mkPkgs system;
          specialArgs = { 
            inherit inputs lib;
            # Make nixicle lib functions available to NixOS modules
            inherit (nixicleLib) mkOpt mkOpt' mkBoolOpt mkBoolOpt' mkPackageOpt mkPackageOpt' enabled disabled;
          };
          modules = commonNixosModules ++ extraModules ++ [
            ./systems/${system}/${hostname}
            {
              nixpkgs.hostPlatform = system;
            }
          ];
        };

      # Helper to create a home-manager configuration (standalone)
      mkHome =
        { username
        , hostname
        , system ? "x86_64-linux"
        , extraModules ? [ ]
        }:
        let
          # Create a module that extends lib with our nixicle functions
          # This module extends whatever lib is already available (including home-manager's extensions)
          nixicleLibModule = { lib, ... }: {
            _module.args.lib = lib.extend (final: prev: {
              nixicle = nixicleLib;
            });
          };
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          extraSpecialArgs = { 
            inherit inputs;
          };
          modules = [
            # Make nixicle helper functions available in all modules via _module.args
            {
              _module.args = {
                inherit (nixicleLib) mkOpt mkOpt' mkBoolOpt mkBoolOpt' mkPackageOpt mkPackageOpt' enabled disabled;
                host = hostname;  # Make hostname available as 'host' argument
              };
            }
          ] ++ commonHomeModules ++ extraModules ++ [
            (./homes + "/${system}/${username}@${hostname}")
            {
              home = {
                username = username;
                homeDirectory = "/home/${username}";
              };
            }
          ];
        };

      # Helper to create home-manager module for NixOS integration
      mkHomeModule =
        { username
        , hostname
        , system ? "x86_64-linux"
        , extraModules ? [ ]
        }:
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { 
              inherit inputs;
              # Don't pass lib here - it breaks home-manager's lib.hm extensions
              # Make nixicle lib functions directly available as arguments
              inherit (nixicleLib) mkOpt mkOpt' mkBoolOpt mkBoolOpt' mkPackageOpt mkPackageOpt' enabled disabled;
              host = hostname;  # Make hostname available as 'host' argument
            };
            users.${username} = {
              imports = commonHomeModules ++ extraModules ++ [
                (./homes + "/${system}/${username}@${hostname}")
              ];
            };
          };
        };

    in
    {
      # NixOS configurations
      nixosConfigurations = {
        framework = mkSystem {
          hostname = "framework";
          extraModules = [
            inputs.nixos-hardware.nixosModules.framework-13-7040-amd
            (mkHomeModule { username = "haseeb"; hostname = "framework"; })
          ];
        };

        workstation = mkSystem {
          hostname = "workstation";
          extraModules = [
            (mkHomeModule { username = "haseeb"; hostname = "workstation"; })
          ];
        };

        vm = mkSystem {
          hostname = "vm";
          extraModules = [
            (mkHomeModule { username = "haseeb"; hostname = "vm"; })
          ];
        };

        ms01 = mkSystem {
          hostname = "ms01";
        };

        s100 = mkSystem {
          hostname = "s100";
        };

        vps = mkSystem {
          hostname = "vps";
        };
      };

      # Standalone home-manager configurations (for non-NixOS systems and standalone use on NixOS)
      homeConfigurations = {
        "haseebmajid@dell" = mkHome {
          username = "haseebmajid";
          hostname = "dell";
        };

        "haseeb@workstation" = mkHome {
          username = "haseeb";
          hostname = "workstation";
        };

        "haseeb@framework" = mkHome {
          username = "haseeb";
          hostname = "framework";
        };

        "haseeb@vm" = mkHome {
          username = "haseeb";
          hostname = "vm";
        };
      };

      # Packages
      packages = forAllSystems (system:
        let pkgs = mkPkgs system;
        in pkgs.nixicle
      );

      # Dev shells
      devShells = forAllSystems (system:
        let pkgs = mkPkgs system;
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nil
              nixfmt-rfc-style
              sops
              age
              ssh-to-age
            ];
          };
        });

      # Deploy-rs configuration
      deploy = nixicleLib.mkDeploy { inherit self; };

      checks = builtins.mapAttrs (
        system: deploy-lib: deploy-lib.deployChecks self.deploy
      ) inputs.deploy-rs.lib;

      # Topology
      topology =
        let
          host = self.nixosConfigurations.${builtins.head (builtins.attrNames self.nixosConfigurations)};
        in
        import inputs.nix-topology {
          inherit (host) pkgs;
          modules = [
            (import ./topology { inherit (host) config; })
            { inherit (self) nixosConfigurations; }
          ];
        };
    };
}
