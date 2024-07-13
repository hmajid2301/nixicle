{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.cli.multiplexers.zellij;
  inherit (config.lib.stylix) colors;

  # zellij-wrapped = pkgs.writeShellApplication {
  #   name = "zellij";
  #   runtimeInputs = [pkgs.zellij];
  #   text = ''
  #     mkdir -p ~/.cache/zellij
  #     cat<<EOF>~/.cache/zellij/permissions.kdl
  #     "${
  #       inputs.zjstatus.packages.${pkgs.system}.default
  #     }/bin/zjstatus.wasm" {
  #         ChangeApplicationState
  #         RunCommands
  #         ReadApplicationState
  #     }
  #     EOF
  #     zellij "$@"
  #   '';
  # };

  sesh = pkgs.writeScriptBin "sesh" ''
    #! /usr/bin/env sh

    # Taken from https://github.com/zellij-org/zellij/issues/884#issuecomment-1851136980
    # select a directory using zoxide
    ZOXIDE_RESULT=$(zoxide query --interactive)
    # checks whether a directory has been selected
    if [[ -z "$ZOXIDE_RESULT" ]]; then
    	# if there was no directory, select returns without executing
    	exit 0
    fi
    # extracts the directory name from the absolute path
    SESSION_TITLE=$(echo "$ZOXIDE_RESULT" | sed 's#.*/##')

    # get the list of sessions
    SESSION_LIST=$(zellij list-sessions -n | awk '{print $1}')

    # checks if SESSION_TITLE is in the session list
    if echo "$SESSION_LIST" | grep -q "^$SESSION_TITLE$"; then
    	# if so, attach to existing session
    	zellij attach "$SESSION_TITLE"
    else
    	# if not, create a new session
    	echo "Creating new session $SESSION_TITLE and CD $ZOXIDE_RESULT"
    	cd $ZOXIDE_RESULT
    	zellij attach -c "$SESSION_TITLE"
    fi
  '';
in {
  options.cli.multiplexers.zellij = with types; {
    enable = mkBoolOpt false "enable zellij multiplexer";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.tmate
      sesh
    ];

    xdg.configFile."zellij/config.kdl".source = ./config.kdl;
    xdg.configFile."zellij/layouts/default.kdl".text = ''
      layout {
          swap_tiled_layout name="vertical" {
              tab max_panes=5 {
                  pane split_direction="vertical" {
                      pane
                      pane { children; }
                  }
              }
              tab max_panes=8 {
                  pane split_direction="vertical" {
                      pane { children; }
                      pane { pane; pane; pane; pane; }
                  }
              }
              tab max_panes=12 {
                  pane split_direction="vertical" {
                      pane { children; }
                      pane { pane; pane; pane; pane; }
                      pane { pane; pane; pane; pane; }
                  }
              }
          }

          swap_tiled_layout name="horizontal" {
              tab max_panes=5 {
                  pane
                  pane
              }
              tab max_panes=8 {
                  pane {
                      pane split_direction="vertical" { children; }
                      pane split_direction="vertical" { pane; pane; pane; pane; }
                  }
              }
              tab max_panes=12 {
                  pane {
                      pane split_direction="vertical" { children; }
                      pane split_direction="vertical" { pane; pane; pane; pane; }
                      pane split_direction="vertical" { pane; pane; pane; pane; }
                  }
              }
          }

          swap_tiled_layout name="stacked" {
              tab min_panes=5 {
                  pane split_direction="vertical" {
                      pane
                      pane stacked=true { children; }
                  }
              }
          }

          swap_floating_layout name="staggered" {
              floating_panes
          }

          swap_floating_layout name="enlarged" {
              floating_panes max_panes=10 {
                  pane { x "5%"; y 1; width "90%"; height "90%"; }
                  pane { x "5%"; y 2; width "90%"; height "90%"; }
                  pane { x "5%"; y 3; width "90%"; height "90%"; }
                  pane { x "5%"; y 4; width "90%"; height "90%"; }
                  pane { x "5%"; y 5; width "90%"; height "90%"; }
                  pane { x "5%"; y 6; width "90%"; height "90%"; }
                  pane { x "5%"; y 7; width "90%"; height "90%"; }
                  pane { x "5%"; y 8; width "90%"; height "90%"; }
                  pane { x "5%"; y 9; width "90%"; height "90%"; }
                  pane focus=true { x 10; y 10; width "90%"; height "90%"; }
              }
          }

          swap_floating_layout name="spread" {
              floating_panes max_panes=1 {
                  pane {y "50%"; x "50%"; }
              }
              floating_panes max_panes=2 {
                  pane { x "1%"; y "25%"; width "45%"; }
                  pane { x "50%"; y "25%"; width "45%"; }
              }
              floating_panes max_panes=3 {
                  pane focus=true { y "55%"; width "45%"; height "45%"; }
                  pane { x "1%"; y "1%"; width "45%"; }
                  pane { x "50%"; y "1%"; width "45%"; }
              }
              floating_panes max_panes=4 {
                  pane { x "1%"; y "55%"; width "45%"; height "45%"; }
                  pane focus=true { x "50%"; y "55%"; width "45%"; height "45%"; }
                  pane { x "1%"; y "1%"; width "45%"; height "45%"; }
                  pane { x "50%"; y "1%"; width "45%"; height "45%"; }
              }
          }

          default_tab_template {
              pane size=2 borderless=true {
                  plugin location="file://${pkgs.zjstatus}/bin/zjstatus.wasm" {
                      format_left   "{mode}#[bg=#${colors.base03}] {tabs}"
                      format_center ""
                      format_right  "#[bg=#${colors.base03},fg=#${colors.base0D}]#[bg=#${colors.base0D},fg=#2d2c3c,bold] #[bg=#2f2e3e,fg=#${colors.base05},bold] {session} #[bg=#${colors.base03},fg=#363a4f,bold]"
                      format_space  ""
                      format_hide_on_overlength "true"
                      format_precedence "crl"

                      border_enabled  "false"
                      border_char     "─"
                      border_format   "#[fg=#6C7086]{char}"
                      border_position "top"

                      mode_normal        "#[bg=#${colors.base0B},fg=#${colors.base03},bold] NORMAL#[bg=#${colors.base03},fg=#${colors.base0B}]█"
                      mode_locked        "#[bg=#${colors.base04},fg=#${colors.base03},bold] LOCKED #[bg=#${colors.base03},fg=#${colors.base04}]█"
                      mode_resize        "#[bg=#${colors.base08},fg=#${colors.base03},bold] RESIZE#[bg=#${colors.base03},fg=#${colors.base08}]█"
                      mode_pane          "#[bg=#${colors.base0D},fg=#${colors.base03},bold] PANE#[bg=#${colors.base03},fg=#${colors.base0D}]█"
                      mode_tab           "#[bg=#${colors.base07},fg=#${colors.base03},bold] TAB#[bg=#${colors.base03},fg=#${colors.base07}]█"
                      mode_scroll        "#[bg=#${colors.base0A},fg=#${colors.base03},bold] SCROLL#[bg=#${colors.base03},fg=#${colors.base0A}]█"
                      mode_enter_search  "#[bg=#${colors.base0D},fg=#${colors.base03},bold] ENT-SEARCH#[bg=#${colors.base03},fg=#${colors.base0D}]█"
                      mode_search        "#[bg=#${colors.base0D},fg=#${colors.base03},bold] SEARCHARCH#[bg=#${colors.base03},fg=#${colors.base0D}]█"
                      mode_rename_tab    "#[bg=#${colors.base07},fg=#${colors.base03},bold] RENAME-TAB#[bg=#${colors.base03},fg=#${colors.base07}]█"
                      mode_rename_pane   "#[bg=#${colors.base0D},fg=#${colors.base03},bold] RENAME-PANE#[bg=#${colors.base03},fg=#${colors.base0D}]█"
                      mode_session       "#[bg=#${colors.base0E},fg=#${colors.base03},bold] SESSION#[bg=#${colors.base03},fg=#${colors.base0E}]█"
                      mode_move          "#[bg=#${colors.base0F},fg=#${colors.base03},bold] MOVE#[bg=#${colors.base03},fg=#${colors.base0F}]█"
                      mode_prompt        "#[bg=#${colors.base0D},fg=#${colors.base03},bold] PROMPT#[bg=#${colors.base03},fg=#${colors.base0D}]█"
                      mode_tmux          "#[bg=#${colors.base09},fg=#${colors.base03},bold] TMUX#[bg=#${colors.base03},fg=#${colors.base09}]█"

                      // formatting for inactive tabs
                      tab_normal              "#[bg=#${colors.base03},fg=#${colors.base0D}]█#[bg=#${colors.base0D},fg=#1e2030,bold]{index} #[bg=#2f2e3e,fg=#${colors.base05},bold] {name}{floating_indicator}#[bg=#${colors.base03},fg=#363a4f,bold]█"
                      tab_normal_fullscreen   "#[bg=#${colors.base03},fg=#${colors.base0D}]█#[bg=#${colors.base0D},fg=#1e2030,bold]{index} #[bg=#2f2e3e,fg=#${colors.base05},bold] {name}{fullscreen_indicator}#[bg=#${colors.base03},fg=#363a4f,bold]█"
                      tab_normal_sync         "#[bg=#${colors.base03},fg=#${colors.base0D}]█#[bg=#${colors.base0D},fg=#1e2030,bold]{index} #[bg=#2f2e3e,fg=#${colors.base05},bold] {name}{sync_indicator}#[bg=#${colors.base03},fg=#363a4f,bold]█"

                      // formatting for the current active tab
                      tab_active              "#[bg=#${colors.base03},fg=#${colors.base09}]█#[bg=#${colors.base09},fg=#1e2030,bold]{index} #[bg=#2f2e3e,fg=#${colors.base05},bold] {name}{floating_indicator}#[bg=#${colors.base03},fg=#363a4f,bold]█"
                      tab_active_fullscreen   "#[bg=#${colors.base03},fg=#${colors.base09}]█#[bg=#${colors.base09},fg=#1e2030,bold]{index} #[bg=#2f2e3e,fg=#${colors.base05},bold] {name}{fullscreen_indicator}#[bg=#${colors.base03},fg=#363a4f,bold]█"
                      tab_active_sync         "#[bg=#${colors.base03},fg=#${colors.base09}]█#[bg=#${colors.base09},fg=#1e2030,bold]{index} #[bg=#2f2e3e,fg=#${colors.base05},bold] {name}{sync_indicator}#[bg=#${colors.base03},fg=#363a4f,bold]█"

                      // separator between the tabs
                      tab_separator           "#[bg=#${colors.base03}] "

                      // indicators
                      tab_sync_indicator       " "
                      tab_fullscreen_indicator " 󰊓"
                      tab_floating_indicator   " 󰹙"

                      command_git_branch_command     "git rev-parse --abbrev-ref HEAD"
                      command_git_branch_format      "#[fg=blue] {stdout} "
                      command_git_branch_interval    "10"
                      command_git_branch_rendermode  "static"

                      datetime        "#[fg=#6C7086,bold] {format} "
                      datetime_format "%A, %d %b %Y %H:%M"
                      datetime_timezone "Europe/London"
                  }
              }
              children
          }
      }
    '';

    programs.zellij = {
      enable = true;
      # package = zellij-wrapped;
      # settings = {
      #   default_mode = "normal";
      #   default_shell = "fish";
      #   simplified_ui = true;
      #   pane_frames = false;
      #   theme = "catppuccin-mocha";
      #   copy_on_select = true;
      # };
    };
  };
}
