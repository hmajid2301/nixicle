{
  imports = [
    ../../home-manager
  ];

  config = {
    modules = {
      editors = {
        nvim.enable = true;
      };

      shells = {
        fish.enable = true;
      };

      terminals = {
        foot.enable = true;
      };
    };
  };
}
