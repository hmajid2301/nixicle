{ pkgs, ... }: {
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings =
      {
        palette = "catppuccin_frappe";
      }
      // builtins.fromTOML (builtins.readFile (pkgs.fetchFromGitHub
        {
          owner = "catppuccin";
          repo = "starship";
          rev = "5629d2356f62a9f2f8efad3ff37476c19969bd4f";
          sha256 = "1bdm1vzapbpnwjby51dys5ayijldq05mw4wf20r0jvaa072nxi4y";
        }
      + /palettes/frappe.toml));
  };
}
