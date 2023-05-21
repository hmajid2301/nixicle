{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rtx-flake = {
      url = "github:jdxcode/rtx";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rtx-flake }:
  flake-utils.lib.eachDefaultSystem(system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ rtx-flake.overlay ];
      };
    in {
      devShells.default = pkgs.mkShell {
        name = "my-dev-env";
        nativeBuildInputs = with pkgs; [
          rtx
        ];
      };
    }
  );
}
