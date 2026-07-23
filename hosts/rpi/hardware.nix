{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  rpiPkgs = inputs.nixos-raspberrypi.packages.${pkgs.stdenv.hostPlatform.system};
  patchedKernelPackages = rpiPkgs.linuxPackages_rpi5.extend (
    _kfinal: kprev: {
      kernel = kprev.kernel.overrideAttrs (old: {
        passthru = (old.passthru or { }) // {
          target = "Image";
        };
      });
    }
  );
in
{
  imports = [
    inputs.disko.nixosModules.disko
  ]
  ++ (with inputs.nixos-raspberrypi.nixosModules; [
    raspberry-pi-5.base
    raspberry-pi-5.display-vc4
  ]);

  boot.loader.raspberry-pi.bootloader = "kernel";
  boot.tmp.useTmpfs = true;

  hardware.deviceTree.enable = true;

  boot.kernelPackages = lib.mkForce patchedKernelPackages;

  hardware.raspberry-pi.config.all.base-dt-params = {
    pciex1 = {
      enable = true;
      value = "on";
    };
    pciex1_gen = {
      enable = true;
      value = "3";
    };
  };
}
