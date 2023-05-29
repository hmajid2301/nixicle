{
  description = "Haseeb's NixOS Flake";

  nixConfig = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://cache.nixos.org/"
    ];

    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rtx-flake = {
      url = "github:jdxcode/rtx";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { nixpkgs, rtx-flake, flake-utils, ... }:
    let 
      system = "x86_64-linux";
      pkgs = import nixpkgs {
          inherit system;
          overlays = [ rtx-flake.overlay ];
        };
    in
  {
    nixosConfigurations = {
      "haseeb" = nixpkgs.lib.nixosSystem {
        modules = [
          ./hardware-configuration.nix
          ./configuration.nix
          ./modules/backup.nix
          ./modules/privacy.nix
        ];
      };
    };
    home.packages = with pkgs; [
      rtx
    ];
  };
}

