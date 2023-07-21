{ pkgs, ... }: {

  xdg.configFile."uair/uair.toml" = {
    source = ./config/uair/uair.toml;
  };
  home.packages = with pkgs; [
    uair
  ];
}
