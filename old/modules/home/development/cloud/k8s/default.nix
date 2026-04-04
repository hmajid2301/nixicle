{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;

let
  cfg = config.development.cloud.k8s;
in
{
  options.development.cloud.k8s = with types; {
    enable = mkBoolOpt false "Whether or not to manage kubernetes";
  };

  config = mkIf cfg.enable {
    programs = {
      k9s = {
        enable = true;
      };
    };

    home.packages = with pkgs; [
      kubectl
      kubectx
      kubelogin
      kubelogin-oidc
      stern
      kubernetes-helm
      kustomize
      fluxcd
      kubefwd
    ];
  };
}
