{delib, ...}:
delib.module {
  name = "development-cloud-k8s";

  options.development.cloud.k8s = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.development.cloud.k8s;
  in
  mkIf cfg.enable {
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
