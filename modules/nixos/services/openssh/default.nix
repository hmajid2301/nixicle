{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.ssh;
in {
  options.services.ssh = with types; {
    enable = mkBoolOpt false "Enable ssh";
    authorizedKeys = mkOpt (listOf str) [] "The public keys to apply.";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = [22];

      settings = {
        PasswordAuthentication = false;
        StreamLocalBindUnlink = "yes";
        GatewayPorts = "clientspecified";
      };
    };
    users.users = {
      ${config.user.name}.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuM4bCeJq0XQ1vd/iNK650Bu3wPVKQTSB0k2gsMKhdE hello@haseebmajid.dev"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHiXSCUnfGG1lxQW470+XBiDgjyYOy5PdHdXsmpraRei haseeb.majid@imaginecurve.com"
      ];
    };
  };
}
