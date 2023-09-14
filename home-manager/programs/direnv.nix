{ pkgs, ... }: {
  home.packages = [
    pkgs.cachix
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
