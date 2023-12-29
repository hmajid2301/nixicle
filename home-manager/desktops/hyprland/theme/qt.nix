{pkgs, ...}: {
  qt = {
    enable = true;
    platformTheme = "qtct";
    style = {
      package =
        pkgs.catppuccin-kvantum.override
        {
          variant = "Mocha";
          accent = "Lavender";
        };
      name = "kvantum";
    };
  };
}
