{ pkgs, ... }:
{
  cli.tools = {
    git.allowedSigners = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev";
    gsesh.enable = true;
  };

  desktops = {
    niri = {
      enable = true;
      extraStartupApps = [
        [ "${pkgs.trayscale}/bin/trayscale" ]
      ];
    };
  };

  roles = {
    desktop.enable = true;
    social.enable = true;
    gaming.enable = true;
    video.enable = true;
  };

  home.stateVersion = "23.11";
}
