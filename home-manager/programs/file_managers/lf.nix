{ pkgs, ... }: {
  programs.lf = {
    enable = true;

    settings = {
      preview = true;
      hidden = true;
      drawbox = true;
      icons = true;
      ignorecase = true;
      sixel = true;
    };

    commands = {
      dragon-out = ''%${pkgs.ripdrag}/bin/ripdrag  -a -x "$fx"'';
      editor-open = ''$$EDITOR $f'';
      mkdir = ''
        ''${{
        	printf "Directory Name: "
        	read DIR
        	mkdir $DIR
        }}
      '';
    };

    keybindings = {
      c = "mkdir";
      do = "dragon-out";
      ee = "editor-open";
      V = ''${pkgs.bat}/bin/bat --paging=always "$f"'';
    };

    extraConfig =
      let
        previewer =
          pkgs.writeShellScriptBin "pv.sh" ''
            case "$(file -Lb --mime-type -- "$1")" in
            		image/*)
            				chafa -f sixel -s "$2x$3" --animate false "$1"
            				exit 1
            				;;
            		*)
            		${pkgs.pistol}/bin/pistol "$file"
            				;;
            esac
          '';
      in
      ''
        set previewer ${previewer}/bin/pv.sh
      '';
  };
}
