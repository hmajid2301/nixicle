{pkgs, ...}: {
  qt = {
    enable = true;
    platformTheme = "qtct";
    style = {
      package = pkgs.catppuccin-kvantum;
      name = "Catppuccin-Macchiato-Blue";
    };
	};
}
