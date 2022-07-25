.DEFAULT_GOAL := help


.PHONY: help
help: ## Generates a help README
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


# prompt_example> make install profile="devcontainer"
.PHONY: install
install: ## Run dotbot install script
	sudo ./install-profile -c $(profile)


vscode-extension-load: ## Install extensions from vscode/extensions.txt
	cat ./vscode/extensions.txt | xargs -L 1 code --install-extension


vscode-extension-dump: ## Save all current extensions to vscode/extensions.txt
	code --list-extensions > ./vscode/extensions.txt


gnome-dump: ## Dump gnome settings
	./gnome/dump.sh


gnome-load: ## Load gnome settings
	./gnome/restore.sh


fisher-dump: SHELL:=/usr/bin/fish
fisher-dump: ## Dump fisher plugins
	fisher list > ./fish/fisher/fishfile


fisher-load: SHELL:=/usr/bin/fish
fisher-load: ## Load fisher plugins
	cat ./fish/fisher/fishfile | xargs -L 1  -I {} fish -c "fisher install {}"