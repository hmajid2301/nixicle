{ pkgs, ... }: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      codeium-nvim
    ];

    extraConfigLua =
      ''
        vim.g.codeium_disable_bindings = 1
        require("codeium").setup()

        vim.keymap.set('i', '<C-a>', function () return vim.fn['codeium#Accept']() end, { expr = true, desc = "Codeium Accept"})
        vim.keymap.set('i', '<M-]>', function() return vim.fn['codeium#CycleCompletions'](1) end, { expr = true, desc = "Codeium Next Suggestion" })
        vim.keymap.set('i', '<M-]>', function() return vim.fn['codeium#CycleCompletions'](-1) end, { expr = true, desc = "Codeium Prev Sugestion" })
        vim.keymap.set('i', '<C-e>', function() return vim.fn['codeium#Clear']() end, { expr = true, desc ="Codeium clear suggestion" })
      '';
  };
}
