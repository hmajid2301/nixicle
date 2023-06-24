{ pkgs, inputs, config, ... }:
{
  #console = {
  #  useXkbConfig = true;
  #  earlySetup = false;
  #};

  boot.plymouth = {
    enable = true;
    themePackages = [ (pkgs.catppuccin-plymouth.override { variant = "frappe"; }) ];
    theme = "catppuccin-frappe";
  };
  boot.kernelParams = [ "quiet" ];
  boot.initrd.systemd.enable = true;
  #loader.timeout = 0;
  #kernelParams = [
  #  #"quiet"
  #  "loglevel=3"
  #  "systemd.show_status=auto"
  #  "udev.log_level=3"
  #  "rd.udev.log_level=3"
  #  "vt.global_cursor_default=0"
  #];
  #consoleLogLevel = 0;
  #initrd.verbose = false;
}

