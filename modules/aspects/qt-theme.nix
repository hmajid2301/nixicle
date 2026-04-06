{ ... }:
{
  den.aspects.qt-theme = {
    homeManager =
      { pkgs, ... }:
      {
        qt = {
          enable = true;
          platformTheme.name = "gtk";
          style = {
            name = "adwaita-dark";
            package = pkgs.adwaita-qt;
          };
        };
      };
  };
}
