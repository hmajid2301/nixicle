{ ... }:
{
  den.aspects.hyprlock = {
    homeManager = { ... }: {
      programs.hyprlock = {
        enable = true;
        settings = { };
      };
    };
  };
}
