{ pkgs, ... }:

{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      palette = "catppuccin_frappe";
    }
    // builtins.fromTOML (builtins.readFile (pkgs.fetchFromGitHub
    {
      owner = "catppuccin";
      repo = "starship";
      rev = "HEAD";
      sha256 = "soEBVlq3ULeiZFAdQYMRFuswIIhI9bclIU8WXjxd7oY=";
    } + /palettes/frappe.toml));
  };
}

