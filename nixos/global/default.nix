# This file (and the global directory) holds config that i use on all hosts
{ pkgs
, inputs
, outputs
, ...
}: {
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      inputs.hyprland.nixosModules.default
      inputs.disko.nixosModules.disko
      inputs.lanzaboote.nixosModules.lanzaboote

      ./locale.nix
      ./nix.nix
      ./openssh.nix
      ./opengl.nix
      ./pam.nix
      ./sops.nix
    ]
    ++ (builtins.attrValues outputs.nixosModules);

  home-manager.extraSpecialArgs = { inherit inputs outputs; };

  hardware.keyboard.zsa.enable = true;
  services.pcscd.enable = true;
  services.udev.packages = with pkgs; [ yubikey-personalization ];
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.fwupd.enable = true;
  services.hardware.bolt.enable = true;
  networking.firewall.enable = true;
  services.printing.enable = true;
  services.dbus.enable = true;
  services.geoclue2.enable = true;
  environment.pathsToLink = [
    "/share/fish"
    "/share/zsh"
    "/share/bash"
  ];

  networking.networkmanager.enable = true;

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };
  nixpkgs.config.joypixels.acceptLicense = true;
  fonts = {
    # Enable a basic set of fonts providing several font styles and families and reasonable coverage of Unicode.
    enableDefaultPackages = false;
    fontDir.enable = true;
    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "FiraCode" "SourceCodePro" "UbuntuMono" ]; })
      fira
      fira-go
      joypixels
      liberation_ttf
      noto-fonts-emoji
      source-serif
      ubuntu_font_family
      work-sans
    ];

    fontconfig = {
      antialias = true;
      defaultFonts = {
        serif = [ "Source Serif" ];
        sansSerif = [ "Work Sans" "Fira Sans" "FiraGO" ];
        monospace = [ "FiraCode Nerd Font Mono" "SauceCodePro Nerd Font Mono" ];
        emoji = [ "Joypixels" "Noto Color Emoji" ];
      };
      enable = true;
      hinting = {
        autohint = false;
        enable = true;
        style = "slight";
      };
      subpixel = {
        rgba = "rgb";
        lcdfilter = "light";
      };
    };
  };
}
