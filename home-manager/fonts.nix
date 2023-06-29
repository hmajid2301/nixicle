{ pkgs, ... }: {
  fontProfiles = {
    enable = true;
    monospace = {
      family = "MonoLisa Nerd Font";
      package = pkgs.monolisa;
    };

    regular = {
      family = "Fira Sans";
      package = pkgs.fira;
    };
  };
}

