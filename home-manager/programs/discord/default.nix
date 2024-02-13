# Adapted from https://github.com/NixOS/nixpkgs/issues/195512#issuecomment-1814318443
# Changes:
#  - Pull the script from sersorrel directly
#  - Use python3.withPackages > writePython3Bin
#  - Copy + alter discord's .desktop file
{pkgs, ...}: let
  patcher = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/sersorrel/sys/f7ff2fa325f786123a9b9e9a61b07be409dfb0b1/hm/discord/krisp-patcher.py";
    hash = "sha256-8AM6v+gR7VH0gXT0orqDSRyXaxv7eV4EnLum5FgW6Yk=";
  };

  python = pkgs.python3.withPackages (ps: [ps.pyelftools ps.capstone]);

  wrapperScript = pkgs.writeShellScript "discord-wrapper" ''
    set -euxo pipefail
    ${pkgs.findutils}/bin/find -L $HOME/.config/discord -name 'discord_krisp.node' -exec ${python}/bin/python3 ${patcher} {} +
    ${pkgs.discord}/bin/discord "$@"
  '';

  wrappedDiscord = pkgs.runCommand "discord" {} ''
    mkdir -p $out/share/applications $out/bin
    ln -s ${wrapperScript} $out/bin/discord
    ${pkgs.gnused}/bin/sed 's!Exec=.*!Exec=${wrapperScript}!g' ${pkgs.discord}/share/applications/discord.desktop > $out/share/applications/discord.desktop
  '';
in {
  xdg.configFile."BetterDiscord/data/stable/custom.css" = {source = ./custom.css;};
  home.packages = [wrappedDiscord];
}
