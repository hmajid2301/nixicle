{
  inputs,
  pkgs,
  ...
}: {
  home.packages = [
    inputs.devenv.packages."${pkgs.system}".devenv
    pkgs.cachix
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
