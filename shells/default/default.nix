{
  pkgs,
  inputs,
  ...
}:
pkgs.mkShell {
  NIX_CONFIG = "extra-experimental-features = nix-command flakes";

  packages = with pkgs; [
    nh
    inputs.nixos-anywhere.packages.${pkgs.system}.nixos-anywhere
    inputs.colmena.packages.${pkgs.system}.colmena

    statix
    deadnix
    alejandra
    home-manager
    git
    sops
    ssh-to-age
    gnupg
    age
  ];
}
