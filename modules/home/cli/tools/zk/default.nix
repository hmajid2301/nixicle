{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
{
  options.cli.tools.zk = with types; {
    enable = mkBoolOpt false "Whether to enable zk note-taking tool";
  };

  config = mkIf config.cli.tools.zk.enable {
    programs.zk = {
      enable = true;

      settings = {
        # Note configuration
        note = {
          language = "en";
          default-title = "Untitled";
          filename = "{{id}}-{{slug title}}";
          extension = "md";
          template = "default.md";
          id-charset = "alphanum";
          id-length = 8;
          id-case = "lower";
        };

        # Format settings
        format = {
          markdown = {
            hashtags = true;
            colon-tags = true;
            multiword-tags = false;
          };
        };

        # Tool configuration
        tool = {
          editor = "nvim";
          pager = "less -FIRX";
          fzf-preview = "bat -p --color always {-1}";
        };

        # LSP configuration for editor integration
        lsp = {
          diagnostics = {
            wiki-title = "hint";
            dead-link = "error";
          };
        };

        # Alias configuration for common commands
        alias = {
          ls = "zk list $@";
          ed = "zk edit $@";
          n = "zk new $@";
        };
      };
    };
  };
}
