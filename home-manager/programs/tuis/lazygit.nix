{ config, ... }:
{
  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        paging = {
          colorArg = "always";
          pager = "delta --color-only --dark --paging=never";
          useConfig = false;
        };
      };
      gui.theme = {
        lightTheme = false;
        activeBorderColor = [ "#${config.colorscheme.colors.base0B}" "bold" ];
        inactiveBorderColor = [ "#${config.colorscheme.colors.base05}" ];
        optionsTextColor = [ "#${config.colorscheme.colors.base0D}" ];
        selectedLineBgColor = [ "#${config.colorscheme.colors.base02}" ];
        selectedRangeBgColor = [ "#${config.colorscheme.colors.base02}" ];
        cherryPickedCommitBgColor = [ "#${config.colorscheme.colors.base0C}" ];
        cherryPickedCommitFgColor = [ "#${config.colorscheme.colors.base0D}" ];
        unstagedChangesColor = [ "#${config.colorscheme.colors.base08}" ];
      };
      customCommands = [
        {
          key = "W";
          command = "git commit -m '{{index .PromptResponses 0}}' --no-verify";
          description = "ignore commit hooks";
          context = "global";
          subprocess = true;
        }
      ];
    };
  };
}

