{ pkgs, ... }:
let
  json2nix = pkgs.writeScriptBin "json2nix" ''
    ${pkgs.python3}/bin/python ${pkgs.fetchurl {
      url = "https://gist.githubusercontent.com/Scoder12/0538252ed4b82d65e59115075369d34d/raw/e86d1d64d1373a497118beb1259dab149cea951d/json2nix.py";
      hash = "sha256-ROUIrOrY9Mp1F3m+bVaT+m8ASh2Bgz8VrPyyrQf9UNQ=";
    }} $@
  '';

  yaml2nix = pkgs.writeScriptBin "yaml2nix" ''
    nix run github:euank/yaml2nix '.args'
  '';
in
{
  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes repl-flake";

    packages = [
      (yaml2nix)
      (json2nix)
      pkgs.statix
      pkgs.deadnix
      pkgs.nixpkgs-fmt
      pkgs.update-nix-fetchgit
      pkgs.home-manager
      pkgs.git
      pkgs.sops
      pkgs.ssh-to-age
      pkgs.gnupg
      pkgs.age
    ];
  };
}
