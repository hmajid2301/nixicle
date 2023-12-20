{ pkgs, ... }: {
  boot = {
    initrd.kernelModules = [
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
      "kvm-amd"
      "kvm-intel"
      "amdgpu"
    ];
  };

  # VM Packages
  environment.systemPackages = with pkgs; [
    libguestfs
    win-virtio
    win-spice
    virt-manager
    virt-viewer
    looking-glass-client
    virtiofsd
  ];
  programs.dconf.enable = true;

  # VM Utilities
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
          packages = [ pkgs.OVMFFull.fd ];
        };
      };
    };
  };

  # TODO: generalise with user
  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0660 haseeb kvm -"
  ];
}
