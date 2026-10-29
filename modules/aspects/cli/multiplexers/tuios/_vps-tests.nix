{ config, lib }:
let
  home = config.home-manager.users.haseeb;
  service = home.systemd.user.services.tuios-web;
  command = lib.concatStringsSep " " (lib.toList service.Service.ExecStart);
  http = config.services.traefik.dynamicConfigOptions.http;
in
lib.runTests {
  testWebIsLoopbackOnlyBehindProxy = {
    expr =
      home.programs.tuios.enable
      && lib.hasInfix "--host 127.0.0.1" command
      && lib.hasInfix "--allow-host tuios.homelab.haseebmajid.dev" command
      && lib.hasInfix "--no-auth" command
      && !(lib.elem 7681 config.networking.firewall.allowedTCPPorts);
    expected = true;
  };
  testProxyRequiresTailnetAndSso = {
    expr = {
      inherit (http.routers.tuios) rule middlewares;
      inherit (http.routers.tuios.tls) certResolver;
      inherit (http.services.tuios.loadBalancer) servers;
    };
    expected = {
      rule = "Host(`tuios.homelab.haseebmajid.dev`)";
      middlewares = [
        "tailnet-only"
        "tinyauth"
      ];
      certResolver = "letsencrypt";
      servers = [ { url = "http://127.0.0.1:7681"; } ];
    };
  };
  testWebPersistsAfterLogout = {
    expr = lib.elem "default.target" service.Install.WantedBy && config.users.users.haseeb.linger;
    expected = true;
  };
  testShellPromptAndHistory = {
    expr =
      home.programs.starship.enable
      && home.programs.starship.settings.palette == "base16"
      && home.programs.atuin.enable
      && home.programs.atuin.enableFishIntegration
      && home.programs.atuin.settings.sync_address == "https://atuin.haseebmajid.dev";
    expected = true;
  };
}
