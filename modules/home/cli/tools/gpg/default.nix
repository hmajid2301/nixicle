{delib, ...}:
delib.module {
  name = "cli-tools-gpg";

  options.cli.tools.gpg = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.tools.gpg;
  in
  mkIf cfg.enable {
    home.packages = [ pkgs.seahorse ];

    services.gnome-keyring.enable = true;

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      enableExtraSocket = true;
      sshKeys = [ "D528D50F4E9F031AACB1F7A9833E49C848D6C90" ];
      pinentry.package = pkgs.pinentry-gnome3;
    };

    programs = {
      gpg = {
        enable = true;
        #homedir = "${config.xdg.dataHome}/gnupg";
      };
    };

    # systemd.user.sockets.gpg-agent = {
    #   listenStreams = let
    #     user = "haseeb";
    #     socketDir =
    #       pkgs.runCommand "gnupg-socketdir" {
    #         nativeBuildInputs = [pkgs.python3];
    #       } ''
    #         python3 ${./gnupgdir.py} '/home/${user}/.local/share/gnupg' > $out
    #       '';
    #   in [
    #     "" # unset
    #     "%t/gnupg/${builtins.readFile socketDir}/S.gpg-agent"
    #   ];
    # };
  };
}
