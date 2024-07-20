{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.home-assistant;
in {
  options.services.nixicle.home-assistant = {
    enable = mkEnableOption "Enable home assistant";
  };

  config = mkIf cfg.enable {
    services.traefik = {
      dynamicConfigOptions = {
        http = {
          services.homeAssistant.loadBalancer.servers = [
            {
              url = "http://localhost:8123";
            }
          ];

          routers.homeAssistant = {
            entryPoints = ["websecure"];
            rule = "Host(`s100.taila5caf.ts.net`)";
            service = "homeAssistant";
            tls.certResolver = "tailscale";
          };
        };
      };
    };

    services.home-assistant = {
      enable = true;
      openFirewall = true;
      extraComponents = [
        "esphome"
        "met"
        "radio_browser"
      ];
      extraPackages = python3Packages:
        with python3Packages; [
          numpy
          aiodhcpwatcher
          aiodiscover
          gtts
        ];
      config = {
        http = {
          server_port = 8123;
          use_x_forwarded_for = true;
          trusted_proxies = ["127.0.0.1" "::1"];
        };
      };
    };
  };
}
