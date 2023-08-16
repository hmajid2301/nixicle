{ pkgs, ... }:

{
  # https://devenv.sh/basics/

  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = [ pkgs.nixpkgs-fmt pkgs.update-nix-fetchgit ];

  # https://devenv.sh/scripts/
  scripts.convert_copied.exec = "wl-paste | ${pkgs.python3} ./converters/json2nix.py /dev/stdin";

  enterShell = ''
  '';
  # https://devenv.sh/languages/
  languages.nix.enable = true;

  # https://devenv.sh/pre-commit-hooks/
  pre-commit.hooks = {
    nixpkgs-fmt.enable = true;
  };

  # https://devenv.sh/processes/
  # processes.ping.exec = "ping example.com";

  # See full reference at https://devenv.sh/reference/options/
}
