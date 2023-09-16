{
  imports = [
    ../../home-manager
		../../home-manager/programs
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
