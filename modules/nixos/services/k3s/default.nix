{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.k3s;
in
{
  options.services.nixicle.k3s = {
    enable = mkEnableOption "Enable The k3s service";
    role = mkOpt (types.nullOr types.str) "server" "Whether this node is a server or agent";
    nodeLabels = mkOpt (types.attrsOf types.str) { } "Labels to apply to the node";
  };

  config = mkIf cfg.enable {
    sops.secrets.k3s_token = {
      sopsFile = ../../roles/kubernetes/secrets.yaml;
    };

    services = {
      k3s = {
        enable = true;
        tokenFile = config.sops.secrets.k3s_token.path;
        extraFlags =
          "--flannel-iface=tailscale0"
          + optionalString (cfg.role == "server") " --disable=traefik"
          + optionalString (cfg.nodeLabels != { }) (
            " " + concatStringsSep " " (mapAttrsToList (k: v: "--node-label \"${k}=${v}\"") cfg.nodeLabels)
          );
        role = mkIf (cfg.role == "agent") "agent";
        # TODO: how can we set this programmatically
        serverAddr = mkIf (cfg.role == "agent") "https://vps:6443";
      };
    };

    systemd.services.k3s = {
      after = [ "tailscaled.service" ];
      wants = [ "tailscaled.service" ];
    };
  };
}
