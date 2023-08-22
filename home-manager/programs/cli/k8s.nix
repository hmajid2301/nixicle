{pkgs, ...}: {
  programs.k9s.enable = true;
  home.packages = with pkgs; [
    kubectl
    kubectx
    kubelogin
    stern
  ];
}
