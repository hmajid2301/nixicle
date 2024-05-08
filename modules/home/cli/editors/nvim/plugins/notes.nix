{
  inputs,
  pkgs,
  ...
}: let
  kanban-nvim = pkgs.vimUtils.buildVimPlugin {
    version = "latest";
    pname = "kanban.nvim";
    src = inputs.kanban-nvim;
  };
in {
  programs.nixvim = {
    extraPlugins = [
      kanban-nvim
    ];

    extraConfigLua = ''
      require("kanban").setup()
    '';

    plugins = {
      headlines.enable = true;
      obsidian = {
        enable = true;
        settings = {
          workspaces = [
            {
              name = "second-brain";
              path = "~/second-brain";
            }
          ];
          dailyNotes = {
            folder = "journal/dailies";
            dateFormat = "%Y-%m-%d";
            aliasFormat = "%B %-d, %Y";
            #template = "daily.md";
          };
          templates = {
            subdir = "templates";
            dateFormat = "%Y-%m-%d";
            timeFormat = "%H:%M";
            substitutions = {};
          };
        };
      };
    };
  };
}
