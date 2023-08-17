{pkgs, ...}: {
  packages = with pkgs; [
    alejandra
    update-nix-fetchgit
    home-manager
    sops
    ssh-to-age
    gnupg
    age
  ];

  scripts.convert_copied.exec = "wl-paste | ${pkgs.python3} ./scripts/converters/json2nix.py /dev/stdin";

  languages.nix.enable = true;

  pre-commit.hooks = {
    alejandra.enable = true;
  };
}
