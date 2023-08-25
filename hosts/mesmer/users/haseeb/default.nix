{
  pkgs,
  config,
  ...
}: {
  sops.secrets.haseeb_password = {
    sopsFile = ../../secrets.yaml;
    neededForUsers = true;
  };

  home-manager.users.haseeb = import ../../home.nix;

  users.users.haseeb = {
    isNormalUser = true;
    shell = pkgs.fish;
    description = "haseeb";
    extraGroups = [
      "wheel"
      "video"
      "audio"
      "networkmanager"
      "libvirtd"
      "kvm"
      "docker"
      "podman"
      "git"
    ];
    passwordFile = config.sops.secrets.haseeb_password.path;
    packages = [pkgs.home-manager];
  };

  programs.fish.enable = true;
  services.geoclue2.enable = true;
  security.pam.services = {
    swaylock = {};
    # TODO: move to yubikey
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };
}
