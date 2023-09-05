{ pkgs, ... }: {
  packages = with pkgs; [
    nixpkgs-fmt
    update-nix-fetchgit
    home-manager
    sops
    ssh-to-age
    gnupg
    age
  ];

  scripts.convert_copied.exec = "wl-paste | ${pkgs.python3}/bin/python3 ./scripts/converters/json2nix.py /dev/stdin";
  scripts.nix2yaml.exec = "nix run github:euank/yaml2nix '.args'";

  languages.nix.enable = true;

  pre-commit.hooks = {
    nixpkgs-fmt.enable = true;
  };
}
