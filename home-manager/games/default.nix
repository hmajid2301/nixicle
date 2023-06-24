{ pkgs, ... }: {
  imports = [
    ./lutris.nix
    ./steam.nix
  ];
  home.packages = with pkgs; [ gamescope ];
}

