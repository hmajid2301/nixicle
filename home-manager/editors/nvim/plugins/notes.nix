{pkgs, ...}: let
  neorg-templates = pkgs.vimUtils.buildVimPlugin rec {
    version = "2.0.3";
    pname = "neorg-templates";
    src = pkgs.fetchFromGitHub {
      owner = "pysan3";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-nZOAxXSHTUDBpUBS/Esq5HHwEaTB01dI7x5CQFB3pcw=";
    };
  };
in {
  programs.nixvim = {
    extraPlugins = [
      neorg-templates
    ];

    plugins = {
      obsidian = {
        enable = true;
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

      neorg = {
        enable = true;
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
          "external.templates".__empty = null;
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
