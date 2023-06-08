{ lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = "Haseeb Majid";
    userEmail = "hello@haseebmajid.dev";

    #signing = {
    #  signByDefault = true;
    #  #key = "A236785D59F190761E9CE8EC78283DB3D233E1F9";
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
        navigate = true;
        light = false;
        side-by-side = false;
      };

      pull =  {
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
