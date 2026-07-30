{ ... }:
let
  port = 8929;
in
{
  den.aspects.redlib = {
    includes = [ ];

    nixos =
      { ... }:
      {
        services.redlib = {
          enable = true;
          address = "127.0.0.1";
          inherit port;
          settings = {
            REDLIB_DEFAULT_HIDE_NSFW = "on";
            REDLIB_ROBOTS_DISABLE_INDEXING = "on";
          };
        };
      };
  };
}
