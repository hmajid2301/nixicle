{ inputs, ... }: {

  home.packages = [
    # TODO: system variable
    inputs.devenv.packages."x86_64-linux".devenv
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
