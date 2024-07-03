{
  programs.nixvim = {
    plugins = {
      auto-session = {
        enable = true;
        extraOptions = {
          auto_save_enabled = true;
          auto_restore_enabled = true;
        };
      };
    };
  };
}
