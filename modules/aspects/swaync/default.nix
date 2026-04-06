{ ... }:
{
  den.aspects.swaync = {
    homeManager = { ... }: {
      services.swaync = {
        enable = true;
        settings = { };
        style = builtins.readFile ./swaync.css;
      };
    };
  };
}
