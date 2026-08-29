{ inputs, ... }: {
  flake-file.inputs = {
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

        nixicle.desktop.greeter = {
          enable = lib.mkDefault (!host.autologin);
          command = lib.mkDefault "${config.programs.noctalia-greeter.package}/bin/noctalia-greeter-session";
          user = lib.mkDefault "greeter";
        };

        programs.noctalia-greeter = {
          enable = config.nixicle.desktop.greeter.enable;
          settings.session.default = "niri";
        };
      };

    homeManager = { inputs, ... }: {
      imports = [
        inputs.noctalia.homeModules.default
        ./noctalia/_home.nix
      ];
    };
  };
}
