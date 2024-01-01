{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.nixos.virtualisation;
in {
  options.modules.nixos.virtualisation = {
    enable = mkEnableOption "Enable virtualisation";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      libguestfs
      win-virtio
      win-spice
      virt-manager
      virt-viewer
      virtiofsd
    ];
    programs.dconf.enable = true;

    virtualisation = {
      kvmgt.enable = true;
      spiceUSBRedirection.enable = true;
      libvirtd = {
        enable = true;
        allowedBridges = [
          "nm-bridge"
          "virbr0"
        ];
        onBoot = "ignore";
        onShutdown = "shutdown";
        qemu = {
          swtpm.enable = true;
          ovmf = {
            enable = true;
            packages = [pkgs.OVMFFull.fd];
          };
        };
      };
    };
  };
}
