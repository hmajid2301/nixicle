{ ... }:
{
  den.aspects.server = {
    homeManager =
      { pkgs, ... }:
      {
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
