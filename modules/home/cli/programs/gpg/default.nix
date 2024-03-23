{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.cli.programs.gpg;
in {
  options.cli.programs.gpg = with types; {
    enable = mkBoolOpt false "Whether or not to enable gpg";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.gnome.seahorse
    ];

    services.gnome-keyring.enable = true;

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      enableExtraSocket = true;
      sshKeys = ["D528D50F4E9F031AACB1F7A9833E49C848D6C90"];
      pinentryPackage = pkgs.pinentry-gnome3;
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
