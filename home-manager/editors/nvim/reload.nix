{
  programs.nixvim = {
    extraConfigLua = ''
      function ReloadConfig()
      	RELOAD = require("plenary.reload").reload_module
      	RELOAD(os.getenv("MYVIMRC"))
      	vim.cmd [[luafile $MYVIMRC]]
      	print(vim.inspect(name .. " RELOADED!!!"))
      end

      vim.api.nvim_set_keymap('n', '<Leader>vs', '<Cmd>lua ReloadConfig()<CR>', { silent = true, noremap = true })
      vim.cmd('command! ReloadConfig lua ReloadConfig()')
    '';
  };
}
