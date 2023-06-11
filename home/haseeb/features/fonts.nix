{ pkgs, ... }: {
  fontProfiles = {
    enable = true;
    monospace = {
      family = "MonoLisa Nerd Font";
    };
    regular = {
      family = "Fira Sans";
      package = pkgs.fira;
    };
  };
}

