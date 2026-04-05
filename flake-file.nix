{ inputs, ... }:
{
  # Root inputs not owned by any specific module
  flake-file.inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  flake-file.inputs.den.url = "github:vic/den";
  flake-file.inputs.import-tree.url = "github:vic/import-tree";

  flake-file.outputs = "flake-module";

  imports = [
    (inputs.import-tree ./modules)
    (inputs.import-tree.match ".*/default\\.nix" ./hosts)
  ];
}
