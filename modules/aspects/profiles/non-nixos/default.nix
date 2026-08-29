_: {
  flake-file.inputs.nixgl.url = "github:nix-community/nixGL";

  den.aspects.non-nixos = {
    homeManager = {
      imports = [
        ./_wrappers.nix
        ./_shell.nix
        ./_session.nix
        ./_services.nix
        ./_xdg.nix
      ];
    };
  };
}
