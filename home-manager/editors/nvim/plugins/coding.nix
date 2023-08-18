{pkgs, ...}: {
  imports = [
    ./coding/cmp.nix
  ];

  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      friendly-snippets
      nvim-surround
    ];
    extraConfigLua =
      # lua
      ''
        require("which-key").register({
          ["<leader>s"] = { name = "+surround" },
        })

        require("luasnip.loaders.from_vscode").lazy_load()

        require("nvim-surround").setup({
          keymaps = {
            normal = "<leader>sa",
            normal_cur = "<leader>sA",
            visual = "<leader>sv",
            visual_line = "<leader>sV",
            delete = "<leader>sd",
            change = "<leader>sc",
            change_line = "<leader>sC",
          },
        })
      '';

    plugins = {
      luasnip = {
        enable = true;
      };

      comment-nvim = {
        enable = true;
      };
    };
  };
}
