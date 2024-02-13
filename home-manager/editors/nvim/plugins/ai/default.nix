{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    plugins = {
      codeium-nvim.enable = true;
      copilot-lua = {
        enable = true;
        suggestion.enabled = false;
        panel.enabled = false;
      };

      copilot-cmp = {
        event = ["InsertEnter" "LspAttach"];
        fixPairs = true;
      };
    };

    extraPlugins = with pkgs.vimPlugins; [
      ChatGPT-nvim
    ];
    extraConfigLua = builtins.readFile ./chatgpt.lua;
  };

  sops.secrets.chatgpt_api_key = {
    sopsFile = ../../../../secrets.yaml;
  };
}
