{pkgs, ...}: {
  home.packages = with pkgs; [
    pritunl-client
  ];
}
