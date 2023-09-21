{ pkgs, ... }: {
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
    packages = [ pkgs.home-manager ];
  };

  programs.fish.enable = true;
  services.geoclue2.enable = true;
}
