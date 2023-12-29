{pkgs, ...}: {
  home.packages = with pkgs; [
    wireshark
    tshark
    termshark
    kubeshark
  ];
}
