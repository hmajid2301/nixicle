{
  desktops.niri = {
    enable = true;
  };

  roles = {
    desktop.enable = true;
    gaming.enable = true;
  };

  cli.tools.ssh.enableKeychain = false;

  gtk.gtk4.theme = null;

  programs.git = {
    signing = {
      format = "ssh";
      signByDefault = true;
    };
  };

  home.stateVersion = "23.11";
}
