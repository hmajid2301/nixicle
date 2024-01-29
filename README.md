<div align="center">
<h1>
<img width="96" src="./images/logo.png"></img> <br>
  Nix Config
</h1>
</h2><img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png" width="500" />
<p></p>
   <a href="https://github.com/hmajid2301/dotfiles/stargazers">
      <img src="https://img.shields.io/github/stars/hmajid2301/dotfiles?color=ca9ee6&labelColor=303446&style=for-the-badge">
   </a>
   <a href="https://github.com/hmajid2301/dotfiles/blob/main">
      <img src="https://img.shields.io/github/repo-size/hmajid2301/dotfiles?color=fab387&labelColor=303446&style=for-the-badge&logo=github&logoColor=fab387">
   </a>
   <a href="https://github.com/hmajid2301/dotfiles/blob/main/LICENSE">
    <img src="https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&logoColor=ca9ee6&colorA=313244&colorB=cba6f7"/>
   </a>
 <p></p>
<img src="https://builtwithnix.org/badge.svg">
 <p></p>
<img src="./images/terminal.png"></img>
<p>
  Screenshot updated: 2024-01-08
</p>
<h4>
  :warning: This config repo is constantly changing, 
  Let me know if you see something that can be improved or done better :smile: .</h4>
</div>

## 💽 Usage

<details>
  <summary>Install</summary>
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

#### Adding Host

To add a new host in the `hosts/` folder. The folder name should be the name of your host i.e. `framework`.
(I recommend look at an example host to see what the files below could look like)
Then add the following files:

##### hardware-configuration.nix

You can create this file running a NixOS ISO (like the ISO we created above). Then run the following command:

```
nixos-generate-config --no-filesystems --root /mnt
cp /mnt/nixos/hardware-configuration.nix ~/dotfiles/hosts/<hostname>
```

##### disks.nix

We use disko to partition the drives for us. During install this file is used to automatically partition our drives.
Add this in a file called `disks.nix`.

##### configuration.nix

If the host is running NixOS to manage the configuration for NixOS create a `configuration.nix` file.
Add imports for all the hardware configuration and disko configuration alongisde the main nixos/global imports
`../../nixos`.

Then decide which optional parts you want such as using setting up docker, vpn or grub bootloader.

```nix
{
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./disks.nix

    ../../nixos
    ../../nixos/users/haseeb.nix
  ];

  modules.nixos = {
    avahi.enable = true;
    backup.enable = true;
    bluetooth.enable = true;
    docker.enable = true;
    fingerprint.enable = true;
    gaming.enable = true;
    login.enable = true;
    extraSecurity.enable = true;
    power.enable = true;
    virtualisation.enable = true;
    vpn.enable = true;
 };
}
```

##### home.nix

This is the entrypoint for home-manager, which is used to to manage most of our apps, anything that can be managed
in the userland i.e. doesn't need "sudo" to run. So this will include things like our editor, terminal, browser.

It contains two main parts, the first part being which apps we want to enable on our host.

```nix
  config = {
    modules = {
      browsers = {
        firefox.enable = true;
      };

      editors = {
        nvim.enable = true;
      };

      multiplexers = {
        tmux.enable = true;
      };

      shells = {
        fish.enable = true;
      };

      terminals = {
        alacritty.enable = true;
        foot.enable = true;
      };
    };
  };
```

Then preferences for colorscheme, wallpaper and default applications to use.

```nix
my.settings = {
  wallpaper = "~/dotfiles/home-manager/wallpapers/rainbow-nix.jpg";
  host = "framework";
  default = {
    shell = "${pkgs.fish}/bin/fish";
    terminal = "wezterm";
    browser = "firefox";
    editor = "nvim";
  };
};

colorscheme = inputs.nix-colors.colorSchemes.catppuccin-mocha;
```

##### flake.nix

Then we need to add our host to the entry i.e. if our device was called `staging`.

```nix
  nixosConfigurations = {
    # VMs
    staging = lib.nixosSystem {
      modules = [ ./hosts/staging/configuration.nix ];
      specialArgs = { inherit inputs outputs; };
    };
  };

  homeConfigurations = {
    # VMs
    staging = lib.homeManagerConfiguration {
      modules = [ ./hosts/staging/home.nix ];
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = { inherit inputs outputs; };
    };
  };
```

> NOTE: You can also just add `home.nix`, if you want to just use home-manager. Or your device is not using NixOS but just the nix package manager.


</details>

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
- Different environments like **hyprland**, **sway** and **gnome**
- Custom live media **ISO**, with an **"automated" install** script
- Custom **neovim** setup declaratively using **nixvim**
- Laptop setup with eGPU and **vfio** for playing games on windows

## 🏠 Structure

- `flake.nix`: Entrypoint for hosts and home configurations
- `nixos`: Configuration applied 
- `hosts`: NixOS Configurations, accessible via `nixos-rebuild --flake`.
  - `framework`: Framework 13th gen laptop | NixOS Hyprland | eGPU 7800 XTX
  - `curve`: Framework 13th gen work laptop | Ubuntu Hyprland
- `home-manager`: Most of my dotfiles configuration, home-manager modules

## 📱 Applications

| Type           | Program      |
| :------------- | :----------: |
| OS             | [NixOS](https://nixos.com/) |
| Editor         | [NeoVim](https://neovim.io/) |
| Multiplexer    | [Zellij](https://github.com/zellij-org/zellij) |
| Prompt         | [Starship](https://starship.rs/) |
| Launcher       | [Rofi](https://github.com/davatorium/rofi) |
| Shell          | [Fish](https://fishshell.com/) |
| Status Bar     | [Waybar](https://github.com/Alexays/Waybar) |
| Terminal       | [Wezterm](https://github.com/wez/wezterm) |
| Window Manager | [Hyprland](https://hyprland.org/) |
| Fonts          | [Mono Lisa](https://www.monolisa.dev/) |
| Colorscheme    | [Catppuccin](https://github.com/catppuccin) |

### Neovim

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

## 🖼️ Showcase

### Desktop

![terminal](images/terminal.png)
![swaync](images/swaync.png)
![games](images/games.png)
![wallpaper](images/wallpaper.png)
![monkeytype](images/monkeytype.png)

### Neovim

![Alpha](images/nvim/alpha.png)
![Telescope](images/nvim/telescope.png)
![Editor](images/nvim/editor.png)
![Go Code](images/nvim/go-code.png)
![CMP](images/nvim/cmp.png)

## Appendix

- <a href="https://www.flaticon.com/free-icons/dot" title="dot icons">Dot icons created by Roundicons - Flaticon</a>
-  You can read more about my dotfiles and development workflows on my [blog here](https://haseebmajid.dev/series/my-development-workflow/) (#ShamelessPlug).
- [Wallpaper From Catppuccin Discord](https://discord.com/channels/907385605422448742/1199293891392852009)

### Inspired By

- Structure and nixlang code: https://github.com/Misterio77/nix-config
- Waybar & scripts: https://github.dev/yurihikari/garuda-sway-config
- Neovim UI: https://github.com/NvChad/nvchad
- README: https://github.com/notohh/snowflake/tree/master
