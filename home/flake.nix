{
  description = "Home Manager configuration of haseeb";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
    in {
      homeConfigurations."haseeb" = home-manager.lib.homeManagerConfiguration {
        # fix: https://github.com/nix-community/home-manager/issues/2942#issuecomment-1119760100
        # nixpkgs.config.allowUnfreePredicate = (pkg: true);
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        modules = [ 
          ./home.nix
        ];
      };
    };
}
