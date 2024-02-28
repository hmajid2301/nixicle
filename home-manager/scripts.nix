{pkgs, ...}: let
  rgv = pkgs.writeScriptBin "rgv" ''
    #!/usr/bin/env bash
    rg --color=always --line-number --no-heading --smart-case "''${*:-}" |
    	fzf --ansi \
    			--color "hl:-1:underline,hl+:-1:underline:reverse" \
    			--delimiter : \
    			--preview 'bat --color=always {1} --highlight-line {2}' \
    			--preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
    			--bind 'enter:become(nvim {1} +{2})'
  '';

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
  home.packages = [
    sesh
    rgv
  ];
}
