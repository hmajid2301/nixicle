_: {
  den.aspects.bitwarden = {
    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages = [ pkgs.rbw ];

        programs.rbw = {
          enable = true;
          settings = {
            email = lib.nixicle.adminEmail;
          };
        };
      };
  };
}
