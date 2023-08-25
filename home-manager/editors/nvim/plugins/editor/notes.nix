{
  programs.nixvim = {
    plugins = {
      zk = {
        enable = true;
        picker = "telescope";
      };
    };
  };
}
