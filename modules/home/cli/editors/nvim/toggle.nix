{
  programs.nixvim = {
    extraConfigLua = builtins.readFile ./lua/toggle.lua;
  };
}
