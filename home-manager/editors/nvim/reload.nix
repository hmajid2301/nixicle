{
  programs.nixvim = {
    extraConfigLua = builtins.readFile ./lua/reload.lua;
  };
}
