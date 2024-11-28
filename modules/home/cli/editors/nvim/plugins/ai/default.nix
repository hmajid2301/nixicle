{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [ollama];

  programs.nixvim = {
    keymaps = [
      {
        action = "<cmd>CopilotChatToggle<CR>";
        key = "<leader>ac";
        options = {
          desc = "Toggle Coilot chat";
        };
        mode = [
          "n"
        ];
      }
      {
        action = "<cmd>ChatGPT<CR>";
        key = "<leader>ag";
        options = {
          desc = "Toggle ChatGPT";
        };
        mode = [
          "n"
        ];
      }
    ];

    plugins = {
      avante = {
        enable = true;
        settings = {
          provider = "copilot";
          auto_suggestions_provider = "copilot";
        };
      };

      chatgpt = {
        enable = true;
        settings = {
          api_key_cmd = "cat ${config.sops.secrets.chatgpt_api_key.path}";
        };
      };

      ollama = {
        enable = true;
      };

      copilot-chat.enable = true;

      copilot-lua = {
        enable = true;
        suggestion = {
          enabled = true;
          autoTrigger = true;
          keymap.accept = "<M-;>";
        };
        panel.enabled = false;
      };

      # codeium-nvim = {
      #   enable = true;
      # };
    };
  };

  sops.secrets.chatgpt_api_key = {
    sopsFile = ../../../../../secrets.yaml;
  };
}
