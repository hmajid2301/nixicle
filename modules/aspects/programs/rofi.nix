_: {
  den.aspects.rofi = {
    homeManager =
      {
        pkgs,
        config,
        lib,
        ...
      }:
      let
        inherit (config.lib.stylix) colors;
        inherit (config.lib.formats.rasi) mkLiteral;
      in
      {
        # TODO(stylix): pr=2501 input=stylix option=stylix.targets.rofi.fonts.enable target=homeConfigurations."haseebmajid@dell".activationPackage
        # Remove this and programs.rofi.settings.font once nix-community/stylix#2501 is merged and locked.
        stylix.targets.rofi.fonts.enable = false;

        programs.rofi = {
          enable = true;
          package = pkgs.rofi;
          settings = {
            font = "${config.stylix.fonts.monospace.name} ${toString config.stylix.fonts.sizes.popups}";
            terminal = "${pkgs.foot}/bin/foot";
            modi = "run,drun,window";
            show-icons = true;
            drun-display-format = "{icon} {name}";
            location = 0;
            disable-history = false;
            hide-scrollbar = true;
            display-drun = "   Apps ";
            display-run = "   Run ";
            display-window = " 﩯  Window";
            display-Network = " 󰤨  Network";
            sidebar-mode = true;
          };
          theme = lib.mkForce {
            "*" = {
              bg-col = mkLiteral "#${colors.base00}";
              bg-col-light = mkLiteral "#${colors.base00}";
              border-col = mkLiteral "#${colors.base00}";
              selected-col = mkLiteral "#${colors.base00}";
              blue = mkLiteral "#${colors.base07}";
              fg-col = mkLiteral "#${colors.base05}";
              fg-col2 = mkLiteral "#${colors.base08}";
              grey = "#737994";
              width = 600;
            };
            "element-text, element-icon , mode-switcher" = {
              background-color = mkLiteral "inherit";
              text-color = mkLiteral "inherit";
            };
            "window" = {
              height = mkLiteral "360px";
              border = mkLiteral "3px";
              border-color = mkLiteral "@border-col";
              background-color = mkLiteral "@bg-col";
            };
            "mainbox".background-color = mkLiteral "@bg-col";
            "inputbar" = {
              children = mkLiteral "[prompt,entry]";
              background-color = mkLiteral "@bg-col";
              border-radius = mkLiteral "5px";
              padding = mkLiteral "2px";
            };
            "prompt" = {
              background-color = mkLiteral "@blue";
              padding = mkLiteral "6px";
              text-color = mkLiteral "@bg-col";
              border-radius = mkLiteral "3px";
              margin = mkLiteral "20px 0px 0px 20px";
            };
            "entry" = {
              padding = mkLiteral "6px";
              margin = mkLiteral "20px 0px 0px 10px";
              text-color = mkLiteral "@fg-col";
              background-color = mkLiteral "@bg-col";
            };
            "listview" = {
              border = mkLiteral "0px 0px 0px";
              padding = mkLiteral "6px 0px 0px";
              margin = mkLiteral "10px 0px 0px 20px";
              columns = 2;
              lines = 5;
              background-color = mkLiteral "@bg-col";
            };
            "element" = {
              padding = mkLiteral "5px";
              background-color = mkLiteral "@bg-col";
              text-color = mkLiteral "@fg-col";
            };
            "element-icon".size = mkLiteral "25px";
            "element selected" = {
              background-color = mkLiteral "@selected-col";
              text-color = mkLiteral "@fg-col2";
            };
            "mode-switcher".spacing = 0;
            "button" = {
              padding = mkLiteral "10px";
              background-color = mkLiteral "@bg-col-light";
              text-color = mkLiteral "@grey";
              vertical-align = mkLiteral "0.5";
              horizontal-align = mkLiteral "0.5";
            };
            "button selected" = {
              background-color = mkLiteral "@bg-col";
              text-color = mkLiteral "@blue";
            };
            "message" = {
              background-color = mkLiteral "@bg-col-light";
              margin = mkLiteral "2px";
              padding = mkLiteral "2px";
              border-radius = mkLiteral "5px";
            };
            "textbox" = {
              padding = mkLiteral "6px";
              margin = mkLiteral "20px 0px 0px 20px";
              text-color = mkLiteral "@blue";
              background-color = mkLiteral "@bg-col-light";
            };
          };
        };
      };
  };
}
