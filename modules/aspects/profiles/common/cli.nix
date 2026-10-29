_: {
  den.aspects.commonCli = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        programs.carapace = {
          enable = true;
          enableFishIntegration = false;
        };

        programs.fish.interactiveShellInit = ''
          source ${
            pkgs.runCommand "carapace-init.fish" { } ''
              ${lib.getExe config.programs.carapace.finalPackage} _carapace fish \
                | sed "s|'/homeless-shelter|\"\$HOME\"'|g" > $out
            ''
          }
        '';
      };
  };
}
