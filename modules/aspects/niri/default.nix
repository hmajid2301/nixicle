{ ... }:
{
  flake-file.inputs = {
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nfsm = {
      url = "github:gvolpe/nfsm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

  den.aspects.niri = {
    includes = [
      (
        {
          host,
          user,
          ...
        }:
        {
          nixos =
            {
              config,
              pkgs,
              lib,
              ...
            }:
            {
              services.greetd = {
                enable = true;
                settings =
                  let
                    session = {
                      command = "niri-session &> /dev/null";
                      user = user.userName;
                    };
                    greeterSession = {
                      command = "${config.programs.noctalia-greeter.package}/bin/noctalia-greeter-session";
                      user = "greeter";
                    };
                  in
                  {
                    default_session = if host.autologin then session else greeterSession;
                  }
                  // lib.optionalAttrs host.autologin { initial_session = session; };
              };

              programs.noctalia-greeter = {
                enable = !host.autologin;
                settings = {
                  session.default = "niri";
                };
              };
            };
        }
      )
    ];

    persist.directories = [ "/var/lib/noctalia-greeter" ];

    nixos = { ... }: {
      imports = [ ./_nixos.nix ];
    };

    homeManager = { ... }: {
      imports = [
        ./_home-base.nix
        ./_home-programs.nix
        ./_home-services.nix
      ];
    };
  };
}
