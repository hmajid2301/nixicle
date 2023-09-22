{ pkgs, ... }: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      codeium-vim
    ];

    extraConfigLua =
      # lua
      ''
        vim.g.codeium_disable_bindings = 1
        vim.keymap.set('i', '<C-a>', function () return vim.fn['codeium#Accept']() end, { expr = true, desc = "Codeium Accept"})
        vim.keymap.set('i', '<M-]>', function() return vim.fn['codeium#CycleCompletions'](1) end, { expr = true, desc = "Codeium Next Suggestion" })
        vim.keymap.set('i', '<M-]>', function() return vim.fn['codeium#CycleCompletions'](-1) end, { expr = true, desc = "Codeium Prev Sugestion" })
        vim.keymap.set('i', '<C-e>', function() return vim.fn['codeium#Clear']() end, { expr = true, desc ="Codeium clear suggestion" })
      '';
  };

  home = {
    file = {
      codeium_ls = {
        target = ".codeium/bin/e829be46431d9d5c061068a9b704357be77f6617/language_server_linux_x64";
        source = "${pkgs.codeium-ls}/bin/language_server_linux_x64";
      };
    };
  };
}
