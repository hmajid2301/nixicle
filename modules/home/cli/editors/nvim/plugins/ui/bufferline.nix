{
  programs.nixvim = {
    plugins.bufferline = {
      enable = false;
      settings = {
        highlights = {
          background = {
            bg = "#252434";
            fg = "#605f6f";
          };

          buffer_selected = {
            bg = "#1E1D2D";
            fg = "#D9E0EE";
          };
          buffer_visible = {
            fg = "#605f6f";
            bg = "#252434";
          };

          error = {
            fg = "#605f6f";
            bg = "#252434";
          };
          error_diagnostic = {
            fg = "#605f6f";
            bg = "#252434";
          };

          close_button = {
            fg = "#605f6f";
            bg = "#252434";
          };
          close_button_visible = {
            fg = "#605f6f";
            bg = "#252434";
          };
          close_button_selected = {
            fg = "#F38BA8";
            bg = "#1E1D2D";
          };
          fill = {
            bg = "#1E1D2D";
            fg = "#605f6f";
          };
          indicator_selected = {
            bg = "#1E1D2D";
            fg = "#1E1D2D";
          };

          modified = {
            fg = "#F38BA8";
            bg = "#252434";
          };
          modified_visible = {
            fg = "#F38BA8";
            bg = "#252434";
          };
          modified_selected = {
            fg = "#ABE9B3";
            bg = "#1E1D2D";
          };

          separator = {
            bg = "#252434";
            fg = "#252434";
          };
          separator_visible = {
            bg = "#252434";
            fg = "#252434";
          };
          separator_selected = {
            bg = "#252434";
            fg = "#252434";
          };

          duplicate = {
            fg = "NONE";
            bg = "#252434";
          };
          duplicate_selected = {
            fg = "#F38BA8";
            bg = "#1E1D2D";
          };
          duplicate_visible = {
            fg = "#89B4FA";
            bg = "#252434";
          };
        };
        options = {
          offsets = [
            {
              filetype = "neo-tree";
              text = "Neo-tree";
              highlight = "Directory";
              text_align = "left";
            }
          ];
        };
      };
    };
  };
}
