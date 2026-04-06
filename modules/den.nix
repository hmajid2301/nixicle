{ inputs, den, ... }:
{
  flake-file.inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  flake-file.inputs.den.url = "github:vic/den";
  flake-file.inputs.import-tree.url = "github:vic/import-tree";
  flake-file.inputs.flake-file.url = "github:vic/flake-file";
  flake-file.inputs.flake-parts = {
    url = "github:hercules-ci/flake-parts";
    inputs.nixpkgs-lib.follows = "nixpkgs";
  };
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = [
    inputs.flake-file.flakeModules.dendritic
    inputs.den.flakeModule
    (inputs.import-tree.match ".*/default\\.nix" ../hosts)
  ];

  _module.args.__findFile = den.lib.__findFile;
}
