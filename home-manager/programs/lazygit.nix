{ pkgs, lib, config, ... }:

let
  fromYAML = f:
    let
      jsonFile =
        pkgs.runCommand "in.json"
          {
            nativeBuildInputs = [ pkgs.jc ];
          } ''
          jc --yaml < "${f}" > "$out"
        '';
    in
    builtins.elemAt (builtins.fromJSON (builtins.readFile jsonFile)) 0;
in
{
  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        paging = {
          colorArg = "always";
          pager = "delta --color-only --dark --paging=never";
          useConfig = false;
        };
      };
      customCommands = [
        {
          key = "W";
          command = "git commit -m '{{index .PromptResponses 0}}' --no-verify";
          description = "ignore commit hooks";
          context = "global";
          subprocess = true;
        }
      ];
    } // fromYAML (pkgs.fetchFromGitHub
      {
        owner = "catppuccin";
        repo = "lazygit";
        rev = "b2ecb6d41b6f54a82104879573c538e8bdaeb0bf";
        sha256 = "0p68z82cq3sgc25l16r8nfny8ab9158jj49xym2a4d932xcnc47l";
      }
    + "/themes/frappe.yml");
  };
}

