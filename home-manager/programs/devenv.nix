{ inputs, pkgs, ... }: {

  home.packages = with pkgs; [
    # TODO: system variable
    inputs.devenv.packages."x86_64-linux".devenv
    cachix
  ];
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
