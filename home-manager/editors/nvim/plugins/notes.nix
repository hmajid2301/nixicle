{pkgs, ...}: {
  programs.nixvim = {
    plugins = {
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
