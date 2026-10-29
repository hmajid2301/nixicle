{ inputs, ... }: {
  flake-file.inputs = {
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-community-plugins = {
      url = "github:noctalia-dev/community-plugins";
      flake = false;
    };
    noctalia-official-plugins = {
      url = "github:noctalia-dev/official-plugins";
      flake = false;
    };
  };

  den.aspects.noctalia = {
    persist.directories = [ "/var/lib/noctalia-greeter" ];

    nixos =
      {
        config,
        lib,
        host,
        pkgs,
        ...
      }:
      {
        imports = [ inputs.noctalia-greeter.nixosModules.default ];

        nix.settings = {
          extra-substituters = [ "https://noctalia.cachix.org" ];
          extra-trusted-public-keys = [
            "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
          ];
        };

        nixicle.desktop.greeter = {
          enable = lib.mkDefault (!host.autologin);
          command = lib.mkDefault "${config.services.displayManager.noctalia-greeter.package}/bin/noctalia-greeter-session";
          user = lib.mkDefault "greeter";
        };

        fonts.packages = [ pkgs.noto-fonts ];

        services.displayManager.noctalia-greeter = {
          enable = config.nixicle.desktop.greeter.enable;
          settings = {
            session.default = "niri";
            appearance = {
              scheme = "Synced";
              theme_mode = "dark";
              font_family = "Noto Sans";
              palette = with config.lib.stylix.colors.withHashtag; {
                primary = base07;
                on_primary = base00;
                secondary = base07;
                on_secondary = base00;
                tertiary = base0C;
                on_tertiary = base00;
                error = base08;
                on_error = base00;
                surface = base00;
                on_surface = base05;
                surface_variant = base01;
                on_surface_variant = base04;
                outline = base03;
                shadow = base00;
                hover = base0C;
                on_hover = base00;
              };
              wallpaper = {
                path = toString pkgs.nixicle.wallpapers.nixppuccin;
                fill_mode = "crop";
              };
            };
            cursor = {
              theme = "Bibata-Modern-Classic";
              path = toString pkgs.bibata-cursors;
              size = 24;
            };
          };
        };
      };

    homeManager = { inputs, ... }: {
      disabledModules = [ "programs/noctalia" ];

      imports = [
        inputs.noctalia.homeModules.default
        ./noctalia/_home.nix
      ];

      nix.settings = {
        extra-substituters = [ "https://noctalia.cachix.org" ];
        extra-trusted-public-keys = [
          "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        ];
      };
    };
  };
}
