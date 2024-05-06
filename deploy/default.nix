{
  nixpkgs,
  inputs,
  ...
}: {
  meta = {
    nixpkgs = import nixpkgs {
      system = "x86_64-linux";
    };
    specialArgs = inputs;
  };

  defaults = {pkgs, ...}: {
    imports = [
      inputs.hardware.nixosModules.raspberry-pi-4
      inputs.sops-nix.nixosModules.sops
      ./common.nix
    ];
  };

  one = {
    imports = [
      ../systems/aarch64-linux/server-1
    ];

    nixpkgs.system = "aarch64-linux";
    deployment = {
      buildOnTarget = true;
      targetHost = "one";
      targetUser = "one";
      tags = ["rpi"];
    };
  };

  two = {
    imports = [
      ../systems/aarch64-linux/server-2
    ];

    nixpkgs.system = "aarch64-linux";
    deployment = {
      buildOnTarget = true;
      targetHost = "two";
      targetUser = "two";
      tags = ["infra" "rpi"];
    };
  };

  three = {
    imports = [
      ../systems/aarch64-linux/server-3
    ];

    nixpkgs.system = "aarch64-linux";
    deployment = {
      buildOnTarget = true;
      targetHost = "three";
      targetUser = "three";
      tags = ["infra" "rpi"];
    };
  };

  four = {
    imports = [
      ../systems/aarch64-linux/server-4
    ];

    nixpkgs.system = "aarch64-linux";
    deployment = {
      targetHost = "four";
      targetUser = "four";
      tags = ["infra" "rpi"];
    };
  };
}
