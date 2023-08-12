{ inputs, pkgs, ... }: {

  home.packages = [
    # TODO: system variable
    inputs.devenv.packages."x86_64-linux".devenv
    pkgs.cachix
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
