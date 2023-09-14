# Shell for bootstrapping flake-enabled nix and other tooling
{ pkgs ? # If pkgs is not defined, instanciate nixpkgs from locked commit
  let
    lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
    nixpkgs = fetchTarball {
      url = "https://github.com/nixos/nixpkgs/archive/${lock.rev}.tar.gz";
      sha256 = lock.narHash;
    };
  in
  import nixpkgs { overlays = [ ]; }
, pre-commit-hooks
, ...
}: {

  default =
    let
      pre-commit-check = pre-commit-hooks.lib.${pkgs.system}.run {
        src = ./.;
        hooks = {
          nixpkgs-fmt.enable = true;
          statix.enable = true;
        };
      };
    in
    pkgs.mkShell {
      inherit (pre-commit-check) shellHook;

      json2nix = pkgs.writeScriptBin "json2nix" ''
        ${pkgs.python3}/bin/python ${pkgs.fetchurl {
          url = "https://gist.githubusercontent.com/Scoder12/0538252ed4b82d65e59115075369d34d/raw/e86d1d64d1373a497118beb1259dab149cea951d/json2nix.py";
          hash = "sha256-ROUIrOrY9Mp1F3m+bVaT+m8ASh2Bgz8VrPyyrQf9UNQ=";
        }} $@
      '';

      yaml2nix = pkgs.writeScriptBin "yaml2nix" ''
        										nix run github:euank/yaml2nix '.args'
      '';

      default = pkgs.mkShell {
        NIX_CONFIG = "extra-experimental-features = nix-command flakes repl-flake";
        nativeBuildInputs = with pkgs; [
          nixpkgs-fmt
          update-nix-fetchgit
          nix
          home-manager
          git
          sops
          ssh-to-age
          gnupg
          age
        ];
      };
    };
}
