{
  pkgs,
  inputs,
  ...
}: let
  neorg = pkgs.vimUtils.buildVimPlugin {
    version = "latest";
    pname = "neorg";
    src = inputs.neorg;
  };
  neorg-templates = pkgs.vimUtils.buildVimPlugin {
    version = "latest";
    pname = "neorg-templates";
    src = inputs.neorg-templates;
  };
in {
  programs.nixvim = {
    extraPlugins = [
      neorg-templates
    ];

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
          #notesSubdir = "notes";
          dailyNotes = {
            folder = "notes/dailies";
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

      neorg = {
        enable = true;
        package = neorg;
        lazyLoading = true;
        modules = {
          "core.defaults".__empty = null;
          "core.concealer".__empty = null;
          "core.summary".__empty = null;
          "core.completion".config.engine = "nvim-cmp";
          "core.dirman".config = {
            workspaces = {
              second_brain = "~/second-brain";
            };
            default_workspace = "second_brain";
          };
          "core.integrations.telescope".__empty = null;
          "external.templates".templates_dir = "~/second-brain/templates";
        };
      };

      treesitter = {
        grammarPackages = with pkgs.tree-sitter-grammars; [
          tree-sitter-norg
          tree-sitter-norg-meta
        ];
      };
    };
  };
}
