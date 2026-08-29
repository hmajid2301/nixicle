{ config, ... }:
{
  home.file.".local/bin/niri-session-nix" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
      exec ${config.home.profileDirectory}/bin/nixGLIntel ${config.home.profileDirectory}/bin/niri-session
    '';
  };
}
