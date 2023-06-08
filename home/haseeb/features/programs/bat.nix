{ pkgs, ... }:

{
  xdg.configFile."bat/themes/catppuccin.tmTheme".text = builtins.readFile (pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/catppuccin/bat/477622171ec0529505b0ca3cada68fc9433648c6/Catppuccin-frappe.tmTheme";
    sha256 = "sha256-v8dycvuCdw/zl4LMpa0pMiNVBuk3CMmSCH8vWS+RIVs";
  });

  xdg.configFile."bat/themes/catppuccin.tmTheme".onChange = "${pkgs.bat}/bin/bat cache --build";
  programs.bat = {
    enable = true;
    config = {
      theme = "catppuccin";
    };
  };
}

