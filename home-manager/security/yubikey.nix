{ pkgs, ... }: {
  home.packages = with pkgs; [
    yubico-piv-tool
    yubioath-flutter
  ];
}
