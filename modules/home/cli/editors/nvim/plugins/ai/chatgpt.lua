require("chatgpt").setup({
	api_key_cmd = "cat ${config.sops.secrets.chatgpt_api_key.path}",
	actions_paths = { "~/dotfiles/home-manager/editors/nvim/plugins/ai/chatgpt-actions.json" },
	chat = {},
	openai_params = {
		model = "gpt-4-0125-preview",
		max_tokens = 4096,
	},
	openai_edit_params = {
		model = "gpt-4-0125-preview",
		max_tokens = 4096,
	},
})
