{
  config,
  pkgs,
  ...
}: {
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    kernelParams = [
      "cgroup_memory=1"
      "cgroup_enable=cpuset"
      "cgroup_enable=memory"
    ];

    initrd.availableKernelModules = ["xhci_pci" "usbhid" "usb_storage"];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = ["noatime"];
    };

    # "/data" = {
    #   device = "/dev/sda";
    #   fsType = "ext4";
    #   options = [ "noatime" ];
    # };
  };

  networking.firewall = {
    allowedUDPPorts = [
      53
      8472
    ];

    allowedTCPPorts = [
      22
      53
      6443
      6444
      9000
    ];
    enable = true;
  };

  programs.fish.enable = true;
  users.users.root.hashedPassword = "!";

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    k3s
    gnupg
  ];

  sops.secrets.k3s_token = {
    sopsFile = ./secrets.yaml;
  };

  sops = {
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  };

  services = {
    tailscale.enable = true;
    k3s.enable = true;
    k3s.tokenFile = config.sops.secrets.k3s_token.path;
    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
        workstation = true;
      };
    };

    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };
  };

  security.sudo.wheelNeedsPassword = false;
  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "23.11";
}
