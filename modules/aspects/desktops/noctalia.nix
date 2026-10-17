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

        services.displayManager.noctalia-greeter = {
          enable = config.nixicle.desktop.greeter.enable;
          settings.session.default = "niri";
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
