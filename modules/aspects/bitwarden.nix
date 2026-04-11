{ ... }:
{
  den.aspects.bitwarden = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.rbw ];

        programs.rbw = {
          enable = true;
          settings = {
            email = "hello@haseebmajid.dev";
          };
        };
      };
  };
}

