# Dotfiles

:house: My dotfiles setup using [Dotbot](https://github.com/anishathalye/dotbot/).

## Install

> :fire: I wouldn't recommend just blinding using my dotfiles. They are setup for my specific use-case.
I think you're off using this repo as reference to create your own dotfiles.

```
git clone git@github.com:hmajid2301/dotfiles.git
cd dotfiles
./install-profile nixos
```

You can read more about my dotfiles and development workflows on my [blog here](https://haseebmajid.dev/series/my-development-workflow/) (#ShamelessPlug)

## System Overview

![neovim](images/dev.png)
![Tmux](images/fun.png)

- OS: NixOS
- DE: Gnome
- Shell: Fish
  - Prompt: [Starship](https://starship.rs/)
- Terminal: Alacritty
  - Editor: Neovim (using [LazyVim](https://www.lazyvim.org) config)
- Colorscheme: [Catppuccin for EVERYTHING!!!](https://github.com/catppuccin)
- Fonts: [Mono Lisa](https://www.monolisa.dev/)

### Extensions

I use the following Gnome extension. You can find the config for the extensions in this [here](linux/nixos/modules/gnome.nix).

- [Pop Shell](https://github.com/pop-os/shell)
- [Space Bar](https://extensions.gnome.org/extension/5090/space-bar/)
- [Smart Auto Move](https://github.com/khimaros/smart-auto-mov)
- [Aylurs Widgets](https://extensions.gnome.org/extension/5338/aylurs-widgets/)
- [AppIndicator](https://extensions.gnome.org/extension/615/appindicator-support/)
- [Blur my Shell](https://extensions.gnome.org/extension/3193/blur-my-shell/)
- [Rounded Window Corners](https://extensions.gnome.org/extension/5237/rounded-window-corners/)
- [Pano](https://extensions.gnome.org/extension/5279/pano/)
- [Extensions Sync](https://github.com/oae/gnome-shell-extensions-sync)
- [Just Perfection](https://extensions.gnome.org/extension/3843/just-perfection/)
- [Logo Menu](https://extensions.gnome.org/extension/4451/logo-menu/)

### Top Bar

![Top Bar](images/topbar.png)

- [Aylurs extension config](https://gitlab.com/hmajid2301/dotfiles/-/blob/93133f7e829409a4a4c943ef38f22ffe2f5c3508/gnome/settings.ini#L763-942)
- Rest of the top bar is configured using css [here](themes/my_theme/gnome-shell/gnome-shell.css)

### Applications

I basically just installed every package from [Modern Unix](https://github.com/ibraheemdev/modern-unix).

CLI tools that I use often include:

- [fzf](https://github.com/junegunn/fzf): Fuzzy search tool
  - Especially for reverse search in my terminal with [fish shell](https://github.com/PatrickF1/fzf.fish)
- [zoxide](https://github.com/ajeetdsouza/zoxide): Smarter cd tool, integrated well with fzf, nvim and tmux
- [exa](https://github.com/ogham/exa): A replacement for `ls` with better syntax highlighting
- [ripgrep](https://github.com/BurntSushi/ripgrep): A faster `grep`
- [navi](https://github.com/denisidoro/navi): Interactive cheat sheet

### Wallpaper

![Wallpaper GIF](images/wallpaper.gif)

I wanted to have wallpaper that changes with the day, I slightly changed the [sunpaper script](https://github.com/hexive/sunpaper).
Which is a great script because it changes depending on the time of day i.e. when sunsets/rises.

## Tmux

I manage my projects using tmux sessions with the
[tmux smart session manager](https://github.com/joshmedeski/t-smart-tmux-session-manager).

Where I create a new session for each project I'm working on and then jump between them.
Where a project might be:

- My Blog
- My Dotfiles
- Full stack application
  - A window for each project i.e. GUI and API

## Neovim

### Screenshots

![Neovim](images/neovim.png)
![Neovim Telescope](images/neovim_telescope.png)
![Neovim Noice](images/neovim_noice.png)

I have started using nvim as my default editor (IDE?). It uses [LazyVim](lazyvim.org/) as
the base config and adds a few plugins on top.

## Appendix

- [Dropbox with extra assets](https://www.dropbox.com/sh/rqs2zce3ugf1dz2/AABam3J8BF5WOCvmYjVSXWKIa?dl=0)
- <a href="https://www.flaticon.com/free-icons/dot" title="dot icons">Dot icons created by Roundicons - Flaticon</a>
- [Wallpaper](https://old.reddit.com/r/wallpapers/comments/3ueq55/lakeside_day_night_transition_credit_louis_coyle/)
- <https://dotfyle.com/hmajid2301/starter>

### Inspired By

- <https://github.com/lime-desu/dootsfile>
- <https://github.com/ghostx31/dotfiles/tree/37587b043f277ff5831ce5f1a3287fbaec1d9fe3>
- <https://github.com/Anant-mishra1729/Village-Linux-rice>
- <https://github.com/colevoss/dotfiles>
