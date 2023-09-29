{
  programs.nixvim = {
    extraConfigLua = ''
      function _G.ReloadConfig()
        for name,_ in pairs(package.loaded) do
            package.loaded[name] = nil
        end

        dofile(vim.env.MYVIMRC)
      end

      vim.api.nvim_set_keymap('n', '<Leader>vs', '<Cmd>lua ReloadConfig()<CR>', { silent = true, noremap = true })
      vim.cmd('command! ReloadConfig lua ReloadConfig()')
    '';
  };
}
