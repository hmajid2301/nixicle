{ lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = "Haseeb Majid";
    userEmail = "hello@haseebmajid.dev";

    #signing = {
    #  signByDefault = true;
    #  key = "F04F 743A 24CD 81B6 28A2  0667 CD20 E737 3D83 B71C";
    #};

    extraConfig = {
      gpg.format = "ssh";

      core = {
        editor = "nvim";
        pager = "delta";
      };

      color = {
        ui = true;
      };

      interactive = {
        diffFitler = "delta --color-only";
      };

      delta = {
        enable = true;
        navigate = true;
        light = false;
        side-by-side = false;
        options.syntax-theme = "catppuccin";
      };

      pull = {
        ff = "only";
      };

      push = {
        default = "current";
        autoSetupRemote = true;
      };

      init = {
        defaultBranch = "init";
      };
    };
  };
}
