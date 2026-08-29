_: {
  den.aspects.wezterm = {
    homeManager = _: {
      programs.wezterm = {
        enable = true;
        # config.lua was not migrated; add extraConfig here when needed
        extraConfig = "";
      };
    };
  };
}
