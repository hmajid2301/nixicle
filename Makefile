.DEFAULT_GOAL := help


.PHONY: help
help: ## Generates a help README
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


# prompt_example> make install profile="devcontainer"
.PHONY: install
install: ## Run dotbot install script
	./install-profile -c $(profile)


gnome-backup: ## Backup gnome settings
	dconf dump / > linux/gnome/settings.ini
	pacman -Qqme > linux/gnome/installs.txt


gnome-restore: ## Restore gnome settings
	dconf load / < linux/gnome/settings.ini
	yay -S $(cat linux/gnome/installs.txt)
