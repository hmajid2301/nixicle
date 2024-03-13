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

  # Based on this https://gist.github.com/CRTified/43b7ce84cd238673f7f24652c85980b3
  config = mkIf cfg.enable {
    #   systemd.user.services.scream-ivshmem = {
    #   enable = true;
    #   description = "Scream IVSHMEM";
    #   serviceConfig = {
    #     ExecStart =
    #       "${pkgs.scream}/bin/scream-ivshmem-pulse /dev/shm/scream";
    #     Restart = "always";
    #   };
    #   wantedBy = [ "multi-user.target" ];
    #   requires = [ "pulseaudio.service" ];
    # };

    environment.systemPackages = with pkgs; [
      libguestfs
      win-virtio
      win-spice
      virt-manager
      virt-viewer
      virtiofsd
      looking-glass-client
    ];

    virtualisation = {
      sharedMemoryFiles = {
        # scream = {
        #   user = "haseeb";
        #   group = "qemu-libvirtd";
        #   mode = "666";
        # };
        looking-glass = {
          user = "haseeb";
          group = "haseeb";
          mode = "666";
        };
      };

      vfio = {
        enable = true;
        IOMMUType = "amd";
        devices = ["10de:2208" "10de:1aef"];
        blacklistNvidia = true;
      };

      hugepages = {
        enable = true;
        defaultPageSize = "1G";
        pageSize = "1G";
        numPages = 16;
      };

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
        clearEmulationCapabilities = false;
        deviceACL = [
          "/dev/input/by-id/usb-Logitech_USB_Receiver-event-mouse"
          "/dev/input/by-id/usb-ZSA_Technology_Labs_Voyager-event-kbd"
          "/dev/vfio/vfio"
          "/dev/vfio/2"
          "/dev/vfio/6"
          "dev/null"
          "/dev/full"
          "/dev/zero"
          "/dev/random"
          "/dev/urandom"
          "/dev/ptmx"
          "/dev/kvm"
          "/dev/kqemu"
          "/dev/rtc"
          "/dev/hpet"
          "/dev/kvm"
          "/dev/shm/looking-glass"
        ];
        qemu = {
          runAsRoot = false;
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
