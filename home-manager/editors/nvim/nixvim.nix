{
  programs.nixvim = {
    enable = true;

    colorschemes.catppuccin = {
      enable = true;
      flavour = "frappe";
    };

    maps.normal = {
      # better up/down
      "j" = {
        action = "v:count == 0 ? 'gj' : 'j'";
        silent = true;
        expr = true;
      };
      "k" = {
        action = "v:count == 0 ? 'gk' : 'k'";
        silent = true;
        expr = true;
      };
    }
      };
  }
