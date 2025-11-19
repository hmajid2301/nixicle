{delib, ...}:
delib.module {
  name = "cli-tools-git";

  options.cli.tools.git = with delib; {
    enable = boolOption false;
    email = strOption "hello@haseebmajid.dev";
    allowedSigners = strOption "";
  };

  home.always = {config, lib, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.tools.git;
  in
  mkIf cfg.enable {
    home.file.".ssh/allowed_signers".text = "* ${cfg.allowedSigners}";

    programs.git = {
      enable = true;

      settings = {
        user = {
          name = "Haseeb Majid";
          email = cfg.email;
          signingkey = "~/.ssh/id_ed25519.pub";
        };

        gpg = {
          format = "ssh";
          ssh.allowedSignersFile = "~/.ssh/allowed_signers";
        };

        commit.gpgsign = true;

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

        url."git@github.com:".insteadOf = "https://github.com/";
      };
    };
  };
}
