{
  programs.nixvim = {
    plugins.bufferline = {
      enable = true;
      highlights = {
        background = {
          bg = "#252434";
          fg = "#605f6f";
        };

        bufferSelected = {
          bg = "#1E1D2D";
          fg = "#D9E0EE";
        };
        bufferVisible = {
          fg = "#605f6f";
          bg = "#252434";
        };

        error = {
          fg = "#605f6f";
          bg = "#252434";
        };
        errorDiagnostic = {
          fg = "#605f6f";
          bg = "#252434";
        };

        closeButton = {
          fg = "#605f6f";
          bg = "#252434";
        };
        closeButtonVisible = {
          fg = "#605f6f";
          bg = "#252434";
        };
        closeButtonSelected = {
          fg = "#F38BA8";
          bg = "#1E1D2D";
        };
        fill = {
          bg = "#1E1D2D";
          fg = "#605f6f";
        };
        indicatorSelected = {
          bg = "#1E1D2D";
          fg = "#1E1D2D";
        };

        modified = {
          fg = "#F38BA8";
          bg = "#252434";
        };
        modifiedVisible = {
          fg = "#F38BA8";
          bg = "#252434";
        };
        modifiedSelected = {
          fg = "#ABE9B3";
          bg = "#1E1D2D";
        };

        separator = {
          bg = "#252434";
          fg = "#252434";
        };
        separatorVisible = {
          bg = "#252434";
          fg = "#252434";
        };
        separatorSelected = {
          bg = "#252434";
          fg = "#252434";
        };

        duplicate = {
          fg = "NONE";
          bg = "#252434";
        };
        duplicateSelected = {
          fg = "#F38BA8";
          bg = "#1E1D2D";
        };
        duplicateVisible = {
          fg = "#89B4FA";
          bg = "#252434";
        };
      };
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
}
