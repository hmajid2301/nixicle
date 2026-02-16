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

    # PAM shim for non-NixOS systems
    # Using 'next' branch for full libpam.so.0 API coverage
    pam-shim = {
      url = "github:Cu3PO42/pam_shim/next";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    # Niri

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nfsm = {
      url = "github:gvolpe/nfsm";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Quickshell

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Services

    tangled = {
      url = "git+https://tangled.sh/@tangled.sh/core";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixery = {
      url = "github:tazjin/nixery";
      flake = false;
    };

    banterbus = {
      url = "gitlab:hmajid2301/banterbus";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zellij plugins
    zellij-pane-tracker = {
      url = "github:theslyprofessor/zellij-pane-tracker";
      flake = false;
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

    oxy2dev-nvim-scripts = {
      url = "github:OXY2DEV/nvim";
      flake = false;
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

    import-tree.url = "github:vic/import-tree";

    nixflix = {
      url = "github:kiriwalawren/nixflix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      lib = nixpkgs.lib.extend (
        self: super: {
          nixicle = import ./lib {
            inherit inputs;
            lib = self;
          };
        }
      );

      overlays = [
        inputs.nixgl.overlay
        inputs.nur.overlays.default
        inputs.nix-topology.overlays.default
        inputs.niri.overlays.niri
        (final: prev: {
          zjstatus = inputs.zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
        })
        (final: prev: {
          nixicle = lib.nixicle.importPackages final ./packages;
        })
      ]
      ++ (map (path: import path { inherit inputs; }) (lib.nixicle.importOverlays ./overlays));

      mkPkgs =
        system:
        import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };

      baseNixosModules = [
        inputs.stylix.nixosModules.stylix
        home-manager.nixosModules.home-manager
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.impermanence.nixosModules.impermanence
        inputs.sops-nix.nixosModules.sops
        inputs.authentik-nix.nixosModules.default
        inputs.tangled.nixosModules.knot
        inputs.tangled.nixosModules.spindle
        inputs.nixflix.nixosModules.nixflix
        inputs.niri.nixosModules.niri
        (inputs.import-tree.match ".*/default\\.nix" ./modules/nixos)
      ];

      commonNixosModules = baseNixosModules ++ [
        inputs.disko.nixosModules.disko
        inputs.nix-topology.nixosModules.default
      ];

      commonHomeModules = [
        inputs.dankMaterialShell.homeModules.dank-material-shell
        inputs.noctalia.homeModules.default
        inputs.sops-nix.homeManagerModules.sops
        inputs.stylix.homeModules.stylix
        inputs.catppuccin.homeModules.catppuccin
        inputs.nix-index-database.homeModules.nix-index
        inputs.pam-shim.homeModules.default
        (inputs.import-tree.match ".*/default\\.nix" ./modules/home)
      ];

      standaloneHomeModules = commonHomeModules ++ [
        inputs.niri.homeModules.niri
        inputs.niri.homeModules.stylix
      ];

      mkSystem =
        {
          hostname,
          system ? "x86_64-linux",
          extraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          pkgs = mkPkgs system;
          specialArgs = {
            inherit inputs lib;
          };
          modules =
            commonNixosModules
            ++ extraModules
            ++ [
              ./hosts/${hostname}
              {
                nixpkgs.hostPlatform = system;
              }
            ];
        };

      mkHome =
        {
          username,
          hostname,
          system ? "x86_64-linux",
          extraModules ? [ ],
        }:
        let
          extendedLib = lib.extend (
            self: super: {
              nixicle = import ./lib {
                inherit inputs;
                lib = self;
              };
            }
          );
        in
        home-manager.lib.homeManagerConfiguration {
          lib = extendedLib;
          pkgs = mkPkgs system;
          extraSpecialArgs = {
            inherit inputs;
            host = hostname;
          };
          modules =
            standaloneHomeModules
            ++ extraModules
            ++ [
              (./hosts + "/${hostname}/home.nix")
              {
                home = {
                  username = username;
                  homeDirectory = "/home/${username}";
                };
              }
            ];
        };

      mkHomeModule =
        {
          username,
          hostname,
          system ? "x86_64-linux",
          extraModules ? [ ],
        }:
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              inherit inputs;
              host = hostname;
            };
            users.${username} = {
              imports = [
                (
                  { lib, ... }:
                  let
                    extendedLib = lib.extend (
                      self: super: {
                        nixicle = import ./lib {
                          inherit inputs;
                          lib = self;
                        };
                      }
                    );
                  in
                  {
                    _module.args.lib = lib.mkForce extendedLib;
                  }
                )
              ]
              ++ commonHomeModules
              ++ extraModules
              ++ [
                (./hosts + "/${hostname}/home.nix")
              ];
            };
          };
        };

    in
    {
      nixosConfigurations = {
        framework = mkSystem {
          hostname = "framework";
          extraModules = [
            (mkHomeModule {
              username = "haseeb";
              hostname = "framework";
            })
          ];
        };

        vm = mkSystem {
          hostname = "vm";
          extraModules = [
            (mkHomeModule {
              username = "haseeb";
              hostname = "vm";
            })
          ];
        };

        framebox = mkSystem {
          hostname = "framebox";
          extraModules = [
            (mkHomeModule {
              username = "haseeb";
              hostname = "framebox";
            })
          ];
        };

        vps = mkSystem {
          hostname = "vps";
        };

      };

      homeConfigurations = {
        "haseebmajid@dell" = mkHome {
          username = "haseebmajid";
          hostname = "dell";
        };

        "haseeb@framework" = mkHome {
          username = "haseeb";
          hostname = "framework";
        };

        "haseeb@vm" = mkHome {
          username = "haseeb";
          hostname = "vm";
        };

        "haseeb@framebox" = mkHome {
          username = "haseeb";
          hostname = "framebox";
        };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        pkgs.nixicle
        // {
          iso-graphical =
            let
              extendedLib = lib.extend (
                self: super: {
                  nixicle = import ./lib {
                    inherit inputs;
                    lib = self;
                  };
                }
              );
            in
            inputs.nixos-generators.nixosGenerate {
              inherit system;
              specialArgs = {
                inherit inputs;
                lib = extendedLib;
              };
              modules = baseNixosModules ++ [
                ./iso/graphical
                {
                  nixpkgs.hostPlatform = system;
                  nixpkgs.overlays = overlays;
                  # Use GNOME live environment
                  image.baseName = lib.mkForce "nixicle-graphical";
                  isoImage.volumeID = lib.mkForce "nixicle-${
                    lib.substring 0 8 (self.lastModifiedDate or self.lastModified or "19700101")
                  }";
                }
              ];
              format = "iso";
            };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        {
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

      deploy = lib.nixicle.mkDeploy {
        inherit self;
        overrides = {
          framebox.profiles.system.sshUser = "haseeb";
          framework.profiles.system.sshUser = "haseeb";
          vm.profiles.system.sshUser = "haseeb";
          vps.profiles.system.sshUser = "nixos";
        };
      };

      checks = builtins.mapAttrs (
        system: deploy-lib: deploy-lib.deployChecks self.deploy
      ) inputs.deploy-rs.lib;

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
