{ lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = "Haseeb Majid";
    userEmail = "hello@haseebmajid.dev";
  };
}
