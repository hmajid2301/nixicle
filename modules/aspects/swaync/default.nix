_: {
  den.aspects.swaync = {
    homeManager = _: {
      services.swaync = {
        enable = true;
        settings = { };
        style = builtins.readFile ./swaync.css;
      };
    };
  };
}
