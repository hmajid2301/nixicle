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
        rev = "3e3e54410c3189053f4da7a7043261361a1ed1bc";
        sha256 = "11pfbly5w5jg44jvgxa8i0h31sqn261l27ahcjibfl5pb9b030dj";
      } + /palettes/frappe.toml));
  };
}

