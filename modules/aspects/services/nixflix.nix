{ den, inputs, ... }:
{
  flake-file.inputs.nixflix = {
    url = "github:kiriwalawren/nixflix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.nixflix = {
    nixos = { ... }: {
      imports = [ inputs.nixflix.nixosModules.nixflix ];
    };
  };
}
