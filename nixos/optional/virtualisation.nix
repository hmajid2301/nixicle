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
    boot = {
      initrd.kernelModules = [
        "vfio_pci"
        "vfio"
        "vfio_iommu_type1"
        "kvm-amd"
        "amdgpu"
      ];

      kernelParams = [
        "amd_iommu=on"
        "iommu=pt"
        "vfio-pci.ids=10de:2208,10de:1aef"
      ];
    };

    environment.systemPackages = with pkgs; [
      libguestfs
      win-virtio
      win-spice
      virt-manager
      virt-viewer
      virtiofsd
      looking-glass-client
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
