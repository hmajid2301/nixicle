_: {
  den.aspects.audiobookshelf = {
    nixos = _: {
      services.audiobookshelf = {
        enable = true;
        port = 8555;
        group = "media";
      };

    };
  };
}
