{
  cli.programs.git.allowedSigners = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev";

  suites = {
    desktop.enable = true;
    gaming.enable = true;
    streaming.enable = true;
  };

  desktops.hyprland.enable = true;

  nixicle.user = {
    enable = true;
    name = "haseeb";
  };

  home.stateVersion = "23.11";
}
