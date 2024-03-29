{
  pkgs,
  inputs,
  ...
}: let
  neorg-templates = pkgs.vimUtils.buildVimPlugin {
    version = "latest";
    pname = "neorg-templates";
    src = inputs.neorg-templates;
  };
in {
  programs.nixvim = {
    extraPlugins = [
      neorg-templates
      pkgs.vimPlugins.headlines-nvim
    ];

    extraConfigLua = ''
      require("headlines").setup()
    '';

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
