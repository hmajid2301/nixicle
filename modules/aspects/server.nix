{ ... }:
{
  den.aspects.server = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.rbw ];

        programs.rbw = {
          enable = true;
          settings = {
            email = "unset";
          };
        };

        programs.zellij = {
          enable = true;
          settings = {
            theme = "stylix";
            default_layout = "compact";
            pane_frames = false;
            simplified_ui = true;
            copy_on_select = true;
            show_startup_tips = false;
          };
        };
      };
  };
}