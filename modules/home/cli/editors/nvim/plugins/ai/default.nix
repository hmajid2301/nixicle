{
  config,
  pkgs,
  inputs,
  ...
}: let
  copilotchat-nvim = pkgs.vimUtils.buildVimPlugin {
    version = "latest";
    pname = "CopilotChat.nvim";
    src = inputs.copilotchat-nvim;
  };
in {
  programs.nixvim = {
    plugins = {
      ollama = {
        enable = true;
      };

      copilot-lua = {
        enable = true;
        suggestion.enabled = false;
        panel.enabled = false;
      };

      codeium-nvim = {
        enable = true;
      };

      copilot-cmp = {
        enable = true;
      };
    };

    extraPlugins = [
      pkgs.vimPlugins.ChatGPT-nvim
      copilotchat-nvim
    ];

    extraConfigLua =
      # lua
      ''
        require("CopilotChat").setup({
        	show_help = "yes",
        })

        require("chatgpt").setup({
        	api_key_cmd = "cat ${config.sops.secrets.chatgpt_api_key.path}",
        	actions_paths = { "~/dotfiles/home/cli/editors/nvim/plugins/ai/chatgpt-actions.json" },
        	chat = {
        		sessions_window = {
        			active_sign = "  ",
        			inactive_sign = "  ",
        		},
        	},
        	openai_params = {
        		model = "gpt-4-0125-preview",
        		max_tokens = 4096,
        	},
        	openai_edit_params = {
        		model = "gpt-4-0125-preview",
        		max_tokens = 4096,
        	},
        })
      '';
  };

  sops.secrets.chatgpt_api_key = {
    sopsFile = ../../../../../secrets.yaml;
  };
}
