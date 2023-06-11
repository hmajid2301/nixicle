# Dotfiles

> THIS IS CURRENTLY A WIP!!! (working on styling hyprland)

:house: My dotfiles repo, setup using nixos/home-manager

## Install

> :fire: I wouldn't recommend just blinding using my dotfiles. They are setup for my specific use-case.
I think you're off using this repo as reference to create your own dotfiles.

```bash
git clone git@github.com:hmajid2301/dotfiles.git ~/dotfiles/
cd dotfiles


nix-shell

# To build system configuration
sudo nixos-rebuild --flake .#framework

# To build user configuration
home-manager --flake .#framework
```

You can read more about my dotfiles and development workflows on my [blog here](https://haseebmajid.dev/series/my-development-workflow/) (#ShamelessPlug).

> Note my dotfiles are almost always changing!

## System Overview

- OS: NixOS
- WM: Hyprland
- Shell: Fish
  - Prompt: [Starship](https://starship.rs/)
- Terminal: Alacritty
  - Editor: Neovim (using [LazyVim](https://www.lazyvim.org) config)
- Colorscheme: [Catppuccin for EVERYTHING!!!](https://github.com/catppuccin)
- Fonts: [Mono Lisa](https://www.monolisa.dev/)

### Applications

I basically just installed every package from [Modern Unix](https://github.com/ibraheemdev/modern-unix).

CLI tools that I use often include:

- [fzf](https://github.com/junegunn/fzf): Fuzzy search tool
  - Especially for reverse search in my terminal with [fish shell](https://github.com/PatrickF1/fzf.fish)
- [zoxide](https://github.com/ajeetdsouza/zoxide): Smarter cd tool, integrated well with fzf, nvim and tmux
- [exa](https://github.com/ogham/exa): A replacement for `ls` with better syntax highlighting
- [ripgrep](https://github.com/BurntSushi/ripgrep): A faster `grep`
- [navi](https://github.com/denisidoro/navi): Interactive cheat sheet

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

I have started using nvim as my default editor (IDE?). It uses [LazyVim](lazyvim.org/) as
the base config and adds a few plugins on top.

## Appendix

- <a href="https://www.flaticon.com/free-icons/dot" title="dot icons">Dot icons created by Roundicons - Flaticon</a>

### Inspired By

- https://github.com/Misterio77/nix-config (Heavily!)
- https://github.dev/yurihikari/garuda-sway-config (mostly scripts)
