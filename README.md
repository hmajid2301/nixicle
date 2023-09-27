<div align="center">
  <h1> :house_with_garden: Haseeb's Dotfiles </h1>
  <a href="https://git.io/typing-svg"><img src="https://readme-typing-svg.demolab.com?font=Fira+Code&pause=1000&color=2A98C9&width=435&lines=My+Dotfiles+repo+setup+using+NixOS" alt="Typing SVG" /></a>
</div>

You can read more about my dotfiles and development workflows on my [blog here](https://haseebmajid.dev/series/my-development-workflow/) (#ShamelessPlug).

## 💽 Usage

> :fire: I wouldn't recommend just blindly using my dotfiles. They are setup for my specific use-case.
I think you're off using this repo as reference to create your own dotfiles.

### Install

To install nixos on any of my devices I create my own ISO live media image. You can build the ISO by doing the following:


```bash
git clone git@github.com:hmajid2301/dotfiles.git ~/dotfiles/
cd dotfiles

nix develop

# To build ISO
sudo nix build .#nixosConfigurations.iso.config.system.build.isoImage
```

After building it you can copy the ISO from the `result` folder to your USB.
Then run `nix_installer`, which will then ask you which host you would like to install.

### Building

To build my dotfiles for a specific host you can do something like:

```bash
git clone git@github.com:hmajid2301/dotfiles.git ~/dotfiles/
cd dotfiles

nix develop

# To build system configuration
sudo nixos-rebuild switch --flake .#framework

# To build user configuration
home-manager switch --flake .#framework
```

## 🚀 Features

Some features of my dotfiles:

- Structured to allow multiple **NixOS configurations**, including **desktop**, **laptop**
- **Declarative** config including **themes**, **wallpapers** and **nix-colors**
- **Opt-in persistance** through impermanence + blank snapshot
- **Encrypted btrfs partition** 
- **sops-nix** for secrets management
- Different environments like **hyprland** and **gnome**
- Laptop setup with eGPU and **vfio** for playing games on windows
- Custom live media **ISO**, with an **"automated" install** script
- Custom **neovim** setup using **nixvim**

## 🏠 Structure

- `flake.nix`: Entrypoint for hosts and home configurations
- `nixos`: 
  - `global`: Configurations that are globally applied to all my machines
  - `optional`: Configurations that some of my machines use
- `hosts`: NixOS Configurations, accessible via `nixos-rebuild --flake`.
  - `framework`: Framework 12th gen laptop | Hyprland | eGPU 3080
  - `curve`: Framework 13th gen work laptop | Ubuntu Hyprland
  - `mesmer`: Desktop AMD Ryzen 9 5950X  | Hyprland | GPU 7900 XTX
- `home-manager`: Most of my dotfiles configuration, user specific

## 📱 Applications

| Type           | Program      |
| :------------- | :----------: |
| OS             | [NixOS](https://nixos.com/) |
| Editor         | [NeoVim](https://neovim.io/) |
| Prompt         | [Starship](https://starship.rs/) |
| Launcher       | [Rofi](https://github.com/davatorium/rofi) |
| Shell          | [Fish](https://fishshell.com/) |
| Status Bar     | [Waybar](https://github.com/Alexays/Waybar) |
| Terminal       | [Alacritty](https://github.com/alacritty/alacritty) |
| Window Manager | [Hyprland](https://hyprland.org/) |
| Fonts          | [Mono Lisa](https://www.monolisa.dev/) |
| Colorscheme    | [Catppuccin](https://github.com/catppuccin) |

I basically just installed every package from [Modern Unix](https://github.com/ibraheemdev/modern-unix).

### Tmux

Some of the plugins I leverage with [tmux](./home-manager/multiplexers/tmux.nix) include:

I manage my projects using tmux sessions with the [tmux smart session manager](https://github.com/joshmedeski/t-smart-tmux-session-manager).

Where I create a new session for each project I'm working on and then jump between them.
Where a project might be:

- My Blog
- My Dotfiles
- Full stack application
  - A window for each project i.e. GUI and API

I also leverage [tmux-browser](https://github.com/ofirgall/tmux-browser), to keep different browser windows for different projects.

Another set of plugins I use are the [tmux-resurrect/continuum](https://github.com/tmux-plugins/tmux-continuum)
plugins to auto save and restore my sessions. Alongside neovim's auto-session we can restore almost everything.

### neovim

My [ neovim config ](./home-manager/editors/nvim/) is made using [nixvim](https://github.com/pta2002/nixvim/).
Which converts all the nix files into a single "large" init.lua file. It also provides an easy way to add
[ extra plugins and extra lua config  ](./home-manager/editors/nvim/plugins/coding.nix) that nixvim itself doesn't provide.

As you will see down below a lot of the UI elements were inspired/copied from nvchad. As I think they have really nice
looking editor altogether. Particularly the cmp menu, telescope and also the status line.

#### Plugins

Some of the main plugins used in my nvim setup include:

- Dashboard: alpha
- Session: auto-session
- Status Line: lualine
- Buffer Line: bufferline
- Winbar: barbecue & navic
- File Explorer: neo-tree
- LSP: lsp, nvim-cmp, luasnip, friendly-snippets
- Git: gitsigns, lazygit
- ColourScheme: notkens12 base46 (nvchad catppuccin)
- Other: telescope (ofc)

## 🖼️Sohowcase

### Desktop

![terminal](images/terminal.png)
![wallpaper](images/wallpaper.png)
![monkeytype](images/monkeytype.png)

### Neovim

![Alpha](images/nvim/alpha.png)
![Telescope](images/nvim/telescope.png)
![Editor](images/nvim/editor.png)
![CMP](images/nvim/cmp.png)

## Appendix

- <a href="https://www.flaticon.com/free-icons/dot" title="dot icons">Dot icons created by Roundicons - Flaticon</a>

### Inspired By

- Structure and nixlang code: https://github.com/Misterio77/nix-config
- Waybar & scripts: https://github.dev/yurihikari/garuda-sway-config
- Neovim UI: https://github.com/NvChad/nvchad
