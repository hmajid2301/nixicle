tar -cvpf ./gnome/custom-icons.tar.gz ~/.icons
tar -cvpf ./gnome/custom-themes.tar.gz ~/.themes
dconf dump / > ./gnome/backup.ini
