{delib, inputs, ...}:
delib.host {
  name = "server-pi-5";
  rice = "catppuccin";

  myconfig = {
    hosts.server-pi-5 = {
      type = "server";
      isServer = true;
      system = "aarch64-linux";
    };
  };

  nixos = {lib, modulesPath, myconfig, ...}: lib.mkIf (myconfig.host.name == "server-pi-5") {
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
  };
}
