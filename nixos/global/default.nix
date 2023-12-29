{
  pkgs,
  inputs,
  outputs,
  ...
}: {
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      inputs.disko.nixosModules.disko
      inputs.lanzaboote.nixosModules.lanzaboote

      ./locale.nix
      ./nix.nix
      ./openssh.nix
      ./opengl.nix
      ./hardware.nix
      ./fonts.nix
      ./pam.nix
      ./sops.nix
    ]
    ++ (builtins.attrValues outputs.nixosModules);

  home-manager.extraSpecialArgs = {inherit inputs outputs;};

  services.pcscd.enable = true;
  services.udev.packages = with pkgs; [yubikey-personalization];
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.fwupd.enable = true;
  networking.networkmanager.enable = true;

  services.dbus.packages = [pkgs.gcr];
  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };
}
