{ inputs, den, ... }:
{
  flake-file.inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    den.url = "github:vic/den";
    import-tree.url = "github:vic/import-tree";
    flake-file.url = "github:vic/flake-file";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  imports = [
    inputs.flake-file.flakeModules.dendritic
    inputs.den.flakeModule
    (inputs.import-tree.match ".*/default\\.nix" ../hosts)
  ];

  _module.args.__findFile = den.lib.__findFile;
}
