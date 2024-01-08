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
in {
  home.packages = [
    rgv
  ];
}
