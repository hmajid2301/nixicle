{ pkgs, ... }: {
  boot.plymouth = {
    enable = true;
    themePackages = [ (pkgs.catppuccin-plymouth.override { variant = "mocha"; }) ];
    theme = "catppuccin-mocha";
  };
  boot.kernelParams = [ "quiet" ];
  boot.initrd.systemd.enable = true;
}
