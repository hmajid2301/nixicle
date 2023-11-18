{ nixpkgs, inputs, ... }: {
  meta = {
    nixpkgs = import nixpkgs {
      system = "x86_64-linux";
    };
    specialArgs = inputs;
  };

  defaults = { pkgs, ... }: {
    imports = [
      inputs.hardware.nixosModules.raspberry-pi-4
      inputs.sops-nix.nixosModules.sops
      ./rpis/common.nix
    ];
  };

  strawberry = {
    imports = [
      ./rpis/strawberry.nix
    ];

    nixpkgs.system = "aarch64-linux";
    deployment = {
      buildOnTarget = true;
      targetHost = "strawberry";
      targetUser = "strawberry";
      tags = [ "rpi" ];
    };
  };

  orange = {
    imports = [
      ./rpis/orange.nix
    ];

    nixpkgs.system = "aarch64-linux";
    deployment = {
      buildOnTarget = true;
      targetHost = "orange";
      targetUser = "orange";
      tags = [ "infra" "rpi" ];
    };
  };

  guava = {
    imports = [
      ./rpis/guava.nix
    ];

    nixpkgs.system = "aarch64-linux";
    deployment = {
      buildOnTarget = true;
      targetHost = "guava";
      targetUser = "guava";
      tags = [ "rpi" ];
    };
  };

  mango = {
    imports = [
      ./rpis/mango.nix
    ];

    nixpkgs.system = "aarch64-linux";
    deployment = {
      targetHost = "mango.local";
      targetUser = "mango";
      tags = [ "infra" "rpi" ];
    };
  };
}
