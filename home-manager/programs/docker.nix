{pkgs, ...}: {
  home.packages = with pkgs; [
    podman-compose
    podman-tui
    lazydocker
  ];
}
