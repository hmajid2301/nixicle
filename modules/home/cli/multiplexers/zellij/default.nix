{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.multiplexers.zellij;
  inherit (config.lib.stylix) colors;

  sesh = pkgs.writeScriptBin "sesh" ''
    #! /usr/bin/env bash

    # Taken from https://github.com/zellij-org/zellij/issues/884#issuecomment-1851136980
    # Modified to handle being called from inside zellij and to support layout selection

    # If a directory is passed as an argument, use it; otherwise use zoxide interactive
    if [[ -n "$1" ]]; then
      ZOXIDE_RESULT="$1"
    else
      # select a directory using zoxide
      ZOXIDE_RESULT=$(zoxide query --interactive)
    fi

    # checks whether a directory has been selected
    if [[ -z "$ZOXIDE_RESULT" ]]; then
    	# if there was no directory, select returns without executing
    	exit 0
    fi

    # extracts the directory name from the absolute path
    SESSION_TITLE=$(echo "$ZOXIDE_RESULT" | sed 's#.*/##')

    # get the list of sessions
    SESSION_LIST=$(zellij list-sessions -n 2>/dev/null | awk '{print $1}')

    # Check if session already exists
    SESSION_EXISTS=$(echo "$SESSION_LIST" | grep -q "^$SESSION_TITLE$" && echo "yes" || echo "no")

    # If session doesn't exist, ask for layout
    if [[ "$SESSION_EXISTS" == "no" ]]; then
      # Available layouts
      LAYOUT=$(${pkgs.gum}/bin/gum choose "default" "dev" "dev-simple" --header "Choose a layout for new session:")
      
      # If user cancelled, exit
      if [[ -z "$LAYOUT" ]]; then
        echo "No layout selected, aborting"
        exit 0
      fi
    fi

    # Check if we're already inside a zellij session
    if [[ -n "$ZELLIJ" ]]; then
      # We're inside zellij, so use zellij action to switch sessions
      if [[ "$SESSION_EXISTS" == "yes" ]]; then
        # Session exists, switch to it
        zellij action switch-mode normal
        zellij action go-to-tab-name "$SESSION_TITLE" 2>/dev/null || {
          # If session exists but we can't switch tabs, try session switching
          echo "Switching to existing session: $SESSION_TITLE"
          zellij action detach
          zellij attach "$SESSION_TITLE"
        }
      else
        # Session doesn't exist, we need to detach and create new session
        echo "Creating new session $SESSION_TITLE at $ZOXIDE_RESULT with layout $LAYOUT"
        zellij action detach
        cd "$ZOXIDE_RESULT"
        zellij --layout "$LAYOUT" attach -c "$SESSION_TITLE"
      fi
    else
      # We're outside zellij, original behavior
      if [[ "$SESSION_EXISTS" == "yes" ]]; then
      	# if so, attach to existing session
      	zellij attach "$SESSION_TITLE"
      else
      	# if not, create a new session with selected layout
      	echo "Creating new session $SESSION_TITLE at $ZOXIDE_RESULT with layout $LAYOUT"
      	cd "$ZOXIDE_RESULT"
      	zellij --layout "$LAYOUT" attach -c "$SESSION_TITLE"
      fi
    fi
  '';

  defaultTabTemplate = ''
    default_tab_template {
        pane size=2 borderless=true {
            plugin location="file://${pkgs.zjstatus}/bin/zjstatus.wasm" {
                format_left   "{mode}#[bg=#${colors.base00}] {tabs}"
                format_center ""
                format_right  "#[bg=#${colors.base00},fg=#${colors.base0D}]#[bg=#${colors.base0D},fg=#${colors.base01},bold] #[bg=#${colors.base02},fg=#${colors.base05},bold] {session} #[bg=#${colors.base03},fg=#${colors.base05},bold]"
                format_space  ""
                format_hide_on_overlength "true"
                format_precedence "crl"

                border_enabled  "false"
                border_char     "─"
                border_format   "#[fg=#6C7086]{char}"
                border_position "top"

                mode_normal        "#[bg=#${colors.base0B},fg=#${colors.base02},bold] NORMAL#[bg=#${colors.base03},fg=#${colors.base0B}]█"
                mode_locked        "#[bg=#${colors.base04},fg=#${colors.base02},bold] LOCKED #[bg=#${colors.base03},fg=#${colors.base04}]█"
                mode_resize        "#[bg=#${colors.base08},fg=#${colors.base02},bold] RESIZE#[bg=#${colors.base03},fg=#${colors.base08}]█"
                mode_pane          "#[bg=#${colors.base0D},fg=#${colors.base02},bold] PANE#[bg=#${colors.base03},fg=#${colors.base0D}]█"
                mode_tab           "#[bg=#${colors.base07},fg=#${colors.base02},bold] TAB#[bg=#${colors.base03},fg=#${colors.base07}]█"
                mode_scroll        "#[bg=#${colors.base0A},fg=#${colors.base02},bold] SCROLL#[bg=#${colors.base03},fg=#${colors.base0A}]█"
                mode_enter_search  "#[bg=#${colors.base0D},fg=#${colors.base02},bold] ENT-SEARCH#[bg=#${colors.base03},fg=#${colors.base0D}]█"
                mode_search        "#[bg=#${colors.base0D},fg=#${colors.base02},bold] SEARCHARCH#[bg=#${colors.base03},fg=#${colors.base0D}]█"
                mode_rename_tab    "#[bg=#${colors.base07},fg=#${colors.base02},bold] RENAME-TAB#[bg=#${colors.base03},fg=#${colors.base07}]█"
                mode_rename_pane   "#[bg=#${colors.base0D},fg=#${colors.base02},bold] RENAME-PANE#[bg=#${colors.base03},fg=#${colors.base0D}]█"
                mode_session       "#[bg=#${colors.base0E},fg=#${colors.base02},bold] SESSION#[bg=#${colors.base03},fg=#${colors.base0E}]█"
                mode_move          "#[bg=#${colors.base0F},fg=#${colors.base02},bold] MOVE#[bg=#${colors.base03},fg=#${colors.base0F}]█"
                mode_prompt        "#[bg=#${colors.base0D},fg=#${colors.base02},bold] PROMPT#[bg=#${colors.base03},fg=#${colors.base0D}]█"
                mode_tmux          "#[bg=#${colors.base09},fg=#${colors.base02},bold] TMUX#[bg=#${colors.base03},fg=#${colors.base09}]█"

                tab_normal              "#[bg=#${colors.base03},fg=#${colors.base0D}]█#[bg=#${colors.base0D},fg=#${colors.base02},bold]{index} #[bg=#${colors.base02},fg=#${colors.base05},bold] {name}{floating_indicator}#[bg=#${colors.base03},fg=#${colors.base02},bold]█"
                tab_normal_fullscreen   "#[bg=#${colors.base03},fg=#${colors.base0D}]█#[bg=#${colors.base0D},fg=#${colors.base02},bold]{index} #[bg=#${colors.base02},fg=#${colors.base05},bold] {name}{fullscreen_indicator}#[bg=#${colors.base03},fg=#${colors.base02},bold]█"
                tab_normal_sync         "#[bg=#${colors.base03},fg=#${colors.base0D}]█#[bg=#${colors.base0D},fg=#${colors.base02},bold]{index} #[bg=#${colors.base02},fg=#${colors.base05},bold] {name}{sync_indicator}#[bg=#${colors.base03},fg=#${colors.base02},bold]█"

                tab_active              "#[bg=#${colors.base03},fg=#${colors.base09}]█#[bg=#${colors.base09},fg=#${colors.base02},bold]{index} #[bg=#${colors.base02},fg=#${colors.base05},bold] {name}{floating_indicator}#[bg=#${colors.base03},fg=#${colors.base02},bold]█"
                tab_active_fullscreen   "#[bg=#${colors.base03},fg=#${colors.base09}]█#[bg=#${colors.base09},fg=#${colors.base02},bold]{index} #[bg=#${colors.base02},fg=#${colors.base05},bold] {name}{fullscreen_indicator}#[bg=#${colors.base03},fg=#${colors.base02},bold]█"
                tab_active_sync         "#[bg=#${colors.base03},fg=#${colors.base09}]█#[bg=#${colors.base09},fg=#${colors.base02},bold]{index} #[bg=#${colors.base02},fg=#${colors.base05},bold] {name}{sync_indicator}#[bg=#${colors.base03},fg=#${colors.base02},bold]█"

                tab_separator           "#[bg=#${colors.base00}] "

                tab_sync_indicator       " "
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
  '';
in
{
  options.cli.multiplexers.zellij = with types; {
    enable = mkBoolOpt false "enable zellij multiplexer";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.tmate
      sesh
    ];

    xdg.configFile."zellij/config.kdl".source = ./config.kdl;
    xdg.configFile."zellij/layouts/dev.kdl".text = ''
      layout {
          tab name="code" focus=true {
              pane {
                  command "nvim"
                  args "."
              }
          }

          tab name="exec" {
              pane split_direction="vertical" {
                  pane {
                      name "main"
                  }
                  pane {
                      name "secondary"
                      size "30%"
                  }
              }
          }

          tab name="dev" {
              pane split_direction="horizontal" {
                  pane {
                      name "dev-server"
                      command "nix"
                      args "develop" "--command" "fish" "-c" "echo 'Starting development server...' && task dev"
                  }
                  pane {
                      name "dev-logs"
                      size "30%"
                      command "fish"
                      args "-c" "echo 'Development logs and monitoring...'"
                  }
              }
          }

          tab name="ai" {
              pane split_direction="vertical" {
                  pane {
                      name "claude-code"
                      command "fish"
                      args "-c" "echo 'AI Assistant Ready!' && echo 'Commands: claude-code, opencode' && fish"
                  }
                  pane {
                      name "ai-context"
                      size "30%"
                      command "fish"
                      args "-c" "echo 'AI Context & Notes' && fish"
                  }
              }
          }

          ${defaultTabTemplate}
      }
    '';

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

          ${defaultTabTemplate}
      }
    '';

    programs.zellij = {
      enable = true;
    };
  };
}
