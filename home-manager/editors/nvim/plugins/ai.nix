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
      {
        plugin = ChatGPT-nvim;
        config =
          # lua
          ''
            require("chatgpt").setup({
            	api_key_cmd = "cat ${config.sops.secrets.chatgpt_api_key.path}"
            })
          '';
      }
    ];
  };

  sops.secrets.chatgpt_api_key = {
    sopsFile = ../../../secrets.yaml;
  };
}
