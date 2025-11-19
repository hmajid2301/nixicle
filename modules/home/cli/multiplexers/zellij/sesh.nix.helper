{ pkgs, ... }:
pkgs.writeScriptBin "sesh" ''
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
''
