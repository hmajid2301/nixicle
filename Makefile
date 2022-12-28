.DEFAULT_GOAL := help


.PHONY: help
help: ## Generates a help README
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


# prompt_example> make install profile="devcontainer"
.PHONY: install
install: ## Run dotbot install script
	./install-profile -c $(profile)


vscode-extension-restore: ## Install extensions from vscode/extensions.txt
	cat ./vscode/extensions.txt | xargs -L 1 code --install-extension


vscode-extension-backup: ## Save all current extensions to vscode/extensions.txt
	code --list-extensions > vscode/extensions.txt


gnome-backup: ## Backup gnome settings
	dconf dump / > gnome/settings.ini
	pacman -Qqme > gnome/installs.txt


gnome-restore: ## Restore gnome settings
	dconf load / < gnome/settings.ini
	yay -S $(cat installs.txt)