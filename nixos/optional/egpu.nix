{pkgs, ...}: {
  boot.kernelModules = ["kvm-amd"];

  systemd.services."all-ways-egpu" = {
    unitConfig = {
      Description = "Configure eGPU as primary under Wayland desktops";
      Before = "display-manager.service";
      After = "bolt.service";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.all-ways-egpu}/bin/all-ways-egpu boot";
    };
    wantedBy = ["graphical.target"];
  };

  systemd.services."all-ways-egpu-shutdown" = {
    unitConfig = {
      Description = "Cleanup boot_vga eGPU configuration at shutdown";
      DefaultDependencies = "no";
      Before = "halt.target shutdown.target reboot.target";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.all-ways-egpu}/bin/all-ways-egpu set-boot-vga internal";
    };
    wantedBy = ["halt.target" "shutdown.target" "reboot.target"];
  };

  systemd.services."all-ways-egpu-boot-vga" = {
    unitConfig = {
      Description = "Configure eGPU as primary using boot_vga under Wayland desktops";
      Before = "display-manager.service bolt.service";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.all-ways-egpu}/bin/all-ways-egpu set-boot-vga egpu";
    };
    wantedBy = ["graphical.target"];
  };

  environment.systemPackages = [
    pkgs.all-ways-egpu
  ];
}
