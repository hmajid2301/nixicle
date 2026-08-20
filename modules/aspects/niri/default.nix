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
    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia/legacy-v4";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.noctalia-qs.follows = "noctalia-qs";
    };
    noctalia-plugins = {
      url = "github:Mic92/noctalia-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
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
                useTextGreeter = !host.autologin;
                settings =
                  let
                    session = {
                      command = "niri-session &> /dev/null";
                      user = user.userName;
                    };
                    greeterSession = {
                      command =
                        let
                          theme =
                            with config.lib.stylix.colors.withHashtag;
                            "border=${base0D};text=${base05};prompt=${base0E};time=${base04};action=${base0B};button=${base0C};container=${base00};input=${base02}";
                        in
                        "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd 'niri-session &> /dev/null' --theme '${theme}'";
                      user = "greeter";
                    };
                  in
                  {
                    default_session = if host.autologin then session else greeterSession;
                  }
                  // lib.optionalAttrs host.autologin { initial_session = session; };
              };
            };
        }
      )
    ];

    persist.directories = [ "/var/cache/tuigreet" ];

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
