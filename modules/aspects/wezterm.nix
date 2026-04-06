{ ... }:
{
  den.aspects.wezterm = {
    homeManager = { ... }: {
      programs.wezterm = {
        enable = true;
        # config.lua was not migrated; add extraConfig here when needed
        extraConfig = "";
      };
    };
  };
}
