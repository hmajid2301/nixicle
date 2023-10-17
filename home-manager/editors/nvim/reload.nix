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


      			function toggle_relative_numbers()
      					if vim.wo.relativenumber then
      							vim.wo.relativenumber = false
      							vim.wo.number = true
      					else
      							vim.wo.relativenumber = true
      							vim.wo.number = false
      					end
      			end

      			vim.api.nvim_set_keymap('n', '<leader>vl', '<Cmd>lua toggle_relative_numbers()<CR>', { noremap = true, silent = true })
    '';
  };
}
