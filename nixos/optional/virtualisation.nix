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
          verbatimConfig = ''
                user = "haseeb"
                  group = "kvm"
            namespaces = []
                       					cgroup_device_acl = [
                        "dev/null", "/dev/full", "/dev/zero",
                        "/dev/random", "/dev/urandom",
                        "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
                        "/dev/rtc","/dev/hpet",
                             "/dev/input/by-id/usb-Logitech_USB_Receiver-event-mouse",
                             "/dev/input/by-id/usb-ZSA_Technology_Labs_Voyager-event-kbd",
                             "/dev/vfio/vfio",
                             "/dev/vfio/2",
                             "/dev/vfio/6",
                             "/dev/kvm",
                             "/dev/shm/scream",
                             "/dev/shm/looking-glass",
                       ]
          '';
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
