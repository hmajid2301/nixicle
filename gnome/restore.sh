dconf load / < ./dotfiles/gnome/backup.ini
tar --extract --file ./gnome/custom-icons.tar.gz -C ~/.icons --strip-components=2
tar --extract --file ./gnome/custom-themes.tar.gz -C ~/.themes --strip-components=2
tar --extract --file ./gnome/wallpaper.zip -C ~/Pictures --strip-components=2
