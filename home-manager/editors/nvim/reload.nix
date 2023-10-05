{
  programs.nixvim = {
    # TODO: maybe move this to keymaps if this works as is.
    extraConfigLua = ''
      vim.api.nvim_set_keymap('n', '<Leader>vs', '<Cmd>lua $MYVIMRC<CR>', { silent = true, noremap = true })
    '';
  };
}
