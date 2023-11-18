{ kubenix, ... }: {
  imports = [ kubenix.modules.helm ];
  kubernetes.kubeconfig = "$HOME/.kube/pis";
  kubernetes.helm.releases.example = {
    chart = kubenix.lib.helm.fetch {
      repo = "https://kubernetes.github.io/dashboard";
      chart = "kubernetes-dashboard ";
      version = "6.0.8";
      sha256 = "sha256-myLGEuL9X4yYyEbHXUMNdk+BkQ0zt0h1ybRrET5U9Xg=";
    };
    values.resources.limits.cpu = "2";
  };
}

