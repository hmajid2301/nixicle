{ den, ... }: {
  flake-file.inputs = {
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nfsm = {
      url = "github:gvolpe/nfsm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nirinit = {
      url = "github:amaanq/nirinit";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.niri = {
    includes = [ den.aspects.rofi ];

    nixos =
      {
        host,
        user,
        config,
        lib,
        ...
      }:
      {
        imports = [ ./_nixos.nix ];

        services.greetd = {
          enable = true;
          settings =
            let
              session = {
                command = "niri-session &> /dev/null";
                user = user.userName;
              };
              greeterSession = {
                command = config.nixicle.desktop.greeter.command;
                user = config.nixicle.desktop.greeter.user;
              };
            in
            {
              default_session =
                if host.autologin || !config.nixicle.desktop.greeter.enable then session else greeterSession;
            }
            // lib.optionalAttrs host.autologin { initial_session = session; };
        };
      };

    homeManager = _: {
      imports = [
        ./_shell.nix
        ./_niri.nix
        ./_nirinit.nix
      ];
    };
  };
}
