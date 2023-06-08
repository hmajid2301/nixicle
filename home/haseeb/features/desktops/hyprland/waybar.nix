{ config, lib, pkgs, user, ... }:

{
  programs.waybar = {
    enable = true;
    systemd = {
      enable = false;
    };
  };
}

