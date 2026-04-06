{ ... }:
{
  den.aspects.matugen = {
    homeManager =
      { ... }:
      {
        # matugen config — customise templates via xdg.configFile."matugen/config.toml"
        # if needed. Packages are added by the dankMaterialShell aspect when dynamic
        # theming is enabled.
      };
  };
}
