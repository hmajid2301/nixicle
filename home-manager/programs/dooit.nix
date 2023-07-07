{ pkgs, ... }: {

  home.packages = with pkgs; [
    dooit
  ];
}
