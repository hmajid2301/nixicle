{ pkgs, ... }: {


  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    kernelParams = [
      "cgroup_memory=1"
      "cgroup_enable=memory"
    ];

    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      22
      6443
    ];
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    k3s
  ];

  services.tailscale.enable = true;
  services.k3s.enable = true;
  services.avahi = {
    enable = true;
    nssmdns = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  security.sudo.wheelNeedsPassword = false;
  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "23.11";
}

