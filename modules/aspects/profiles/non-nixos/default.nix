_: {
  flake-file.inputs = {
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pam-shim = {
      url = "github:Cu3PO42/pam_shim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.non-nixos = {
    homeManager =
      { inputs, lib, ... }:
      {
        imports = [
          inputs.pam-shim.homeModules.default
          ./_wrappers.nix
          ./_shell.nix
          ./_session.nix
          ./_services.nix
          ./_xdg.nix
        ];

        pamShim.enable = true;

        programs.fish.interactiveShellInit = lib.mkAfter ''
          fish_add_path --global --path --move /usr/local/bin /usr/bin
        '';
      };
  };
}
