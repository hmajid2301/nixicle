{ ... }:
{
  den.aspects.swaylock = {
    homeManager =
      { pkgs, ... }:
      {
        programs.swaylock = {
          enable = true;
          package = pkgs.swaylock-effects;
          settings = {
            show-failed-attempts = true;
            screenshots = true;
            clock = true;
            indicator = true;
            indicator-radius = 350;
            indicator-thickness = 5;
            effect-blur = "7x5";
            effect-vignette = "0.5x0.5";
            fade-in = 0.2;
            font = "MonoLisa Nerd Font";
          };
        };
      };
  };
}
