{ den, ... }:
{
  den.aspects.kvm = {
    nixos = { pkgs, ... }: {
      virtualisation = {
        kvmgt.enable = true;
        spiceUSBRedirection.enable = true;
        libvirtd = {
          enable = true;
          allowedBridges = [ "nm-bridge" "virbr0" ];
          onBoot = "ignore";
          onShutdown = "shutdown";
          qemu.swtpm.enable = true;
        };
      };
      environment.systemPackages = with pkgs; [
        libguestfs virtio-win win-spice virt-manager virt-viewer
      ];
    };
  };
}
