{
  lib,
  modulesPath,
  inputs,
  ...
}:
with lib;
with lib.nixicle; {
  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // {allowMissing = true;});
    })
  ];

  imports = with inputs.nixos-hardware.nixosModules; [
    (modulesPath + "/installer/scan/not-detected.nix")
    raspberry-pi-5
  ];

  roles = {
    server.enable = true;
  };

  sdImage.compressImage = false;
  system.boot.enable = lib.mkForce false;
  hardware.raspberry-pi-5.enable = true;

  system.stateVersion = "23.11";
}
