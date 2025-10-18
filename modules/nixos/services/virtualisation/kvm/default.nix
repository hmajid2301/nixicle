{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.virtualisation.kvm;
in {
  options.services.virtualisation.kvm = {
    enable = lib.mkEnableOption "enable kvm virtualisation";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      libguestfs
      win-virtio
      win-spice
      virt-manager
      virt-viewer
    ];

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

        };
      };
    };
  };
}
