{
  inputs,
  lib,
  den,
  ...
}:
let
  inherit ((import ../lib { inherit inputs lib; })) extendedLib;

  overlays = [
    extendedLib.nixicle.overlays.nur
    extendedLib.nixicle.overlays.niri
    extendedLib.nixicle.overlays.zjstatus
    extendedLib.nixicle.overlays.nixicle
  ];

  mkInstantiate =
    { modules }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit modules;
      specialArgs = {
        inherit inputs;
        lib = extendedLib;
      };
    };

  mkPiInstantiate =
    { modules }:
    inputs.nixos-raspberrypi.lib.nixosSystem {
      inherit (inputs) nixpkgs;
      inherit modules;
      specialArgs = {
        inherit inputs;
        lib = extendedLib;
      };
    };

  mkHomeInstantiate =
    { modules, ... }:
    let
      hmLib = inputs.home-manager.lib.hm;
      hmExtendedLib = extendedLib.extend (_self: _super: { hm = hmLib; });
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        inherit overlays;
        config.allowUnfreePredicate = extendedLib.nixicle.allowUnfreePredicate;
      };
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs;
        lib = hmExtendedLib;
      };
      inherit modules;
    };

  haseebUser = {
    authorizedKeys = extendedLib.nixicle.authorizedKeys;
    email = extendedLib.nixicle.adminEmail;
    signingKey = "~/.ssh/id_ed25519.pub";
  };
in
{
  den = {
    aspects = {
      haseeb = {
        includes = [
          den.batteries.primary-user
          (den.batteries.user-shell "fish")
        ];

        provides.vps = {
          includes = [
            den.aspects.fish
            den.aspects.shellPromptHistory
            den.aspects.git
            den.aspects.ssh
            den.aspects.herdr-cli
            den.aspects.tuios
            den.aspects.ai
            den.aspects.worktrunk
            den.aspects.devTools
          ];

          homeManager =
            {
              config,
              pkgs,
              ...
            }:
            {
              imports = [
                inputs.sops-nix.homeManagerModules.sops
                inputs.stylix.homeModules.stylix
              ];

              sops = {
                age = {
                  generateKey = true;
                  keyFile = "/home/${config.home.username}/.config/sops/age/keys.txt";
                  sshKeyPaths = [ "/home/${config.home.username}/.ssh/id_ed25519" ];
                };
                defaultSymlinkPath = "/run/user/1002/secrets";
                defaultSecretsMountPoint = "/run/user/1002/secrets.d";
              };

              stylix = {
                enable = true;
                autoEnable = false;
                base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
                targets.starship.enable = true;
              };

              systemd.user.services.herdr-server = {
                Unit = {
                  Description = "Persistent Herdr agent server";
                  After = [ "network-online.target" ];
                  Wants = [ "network-online.target" ];
                  X-RestartIfChanged = false;
                };
                Service = {
                  ExecStart = "${
                    inputs.herdr-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
                  }/bin/herdr server";
                  Restart = "on-failure";
                  RestartSec = 5;
                  UMask = "0077";
                  WorkingDirectory = "/home/haseeb";
                };
                Install.WantedBy = [ "default.target" ];
              };

              systemd.user.services.tuios-web = {
                Unit = {
                  Description = "Tailscale-only TUIOS web terminal";
                  After = [ "network-online.target" ];
                  Wants = [ "network-online.target" ];
                };
                Service = {
                  ExecStart = "${config.programs.tuios.package}/bin/tuios-web --host 127.0.0.1 --port 7681 --allow-host tuios.homelab.haseebmajid.dev --no-auth --default-session phone";
                  Restart = "on-failure";
                  RestartSec = 5;
                  UMask = "0077";
                  WorkingDirectory = config.home.homeDirectory;
                };
                Install.WantedBy = [ "default.target" ];
              };

              programs = {
                bat.enable = true;
                bottom.enable = true;
                direnv = {
                  enable = true;
                  nix-direnv.enable = true;
                };
                eza.enable = true;
                fzf.enable = true;
                htop.enable = true;
                yazi = {
                  enable = true;
                  enableFishIntegration = true;
                  shellWrapperName = "y";
                };
                superfile.enable = true;
                zoxide = {
                  enable = true;
                  enableFishIntegration = true;
                };
              };

              home = {
                stateVersion = "26.05";
                packages = with pkgs; [
                  curlie
                  delta
                  duf
                  dust
                  fd
                  gnumake
                  hyperfine
                  jq
                  mutagen
                  neovim
                  procs
                  ripgrep
                  tokei
                  tmux
                  unzip
                  yq-go
                ];
              };
            };
        };
      };
    };

    hosts.x86_64-linux = {
      framework = {
        isLaptop = true;
        autologin = false;
        primaryDisplay = {
          name = "eDP-1";
          width = 2256;
          height = 1504;
          refresh = 120;
        };
        instantiate = mkInstantiate;
        users.haseeb = haseebUser;
      };

      vm = {
        instantiate = mkInstantiate;
        users.haseeb = haseebUser;
      };

      desktop = {
        autologin = false;
        instantiate = mkInstantiate;
        users.haseeb = haseebUser;
      };

      nas = {
        instantiate = mkInstantiate;
        users.haseeb = haseebUser;
      };

      vps = {
        instantiate = mkInstantiate;
        users.haseeb = {
          authorizedKeys = [ ];
          email = extendedLib.nixicle.adminEmail;
          signingKey = "~/.ssh/id_ed25519.pub";
        };
      };
    };

    hosts.aarch64-linux = {
      rpi = {
        instantiate = mkPiInstantiate;
      };
    };

    homes = {
      x86_64-linux = {
        "haseebmajid@dell" = {
          isLaptop = true;
          instantiate = mkHomeInstantiate;
        };

        "haseeb@framework" = {
          isLaptop = true;
          instantiate = mkHomeInstantiate;
        };

        "haseeb@desktop" = {
          instantiate = mkHomeInstantiate;
        };
      };
    };
  };
}
