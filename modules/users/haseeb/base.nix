{ den, ... }:
{
  den.aspects.haseeb = {
    homeManager = { ... }: {
      gtk.gtk4.theme = null;
      programs.git = {
        signing = {
          format = "ssh";
          signByDefault = true;
        };
      };
    };
  };
}
