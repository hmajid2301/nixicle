_: {
  den.aspects.audiobookshelf = {
    nixos =
      { lib, ... }:
      {
        # Self-contained: hosts that enable audiobookshelf without the media
        # stack (nixflix/jellyfin) still need the group it runs as.
        users.groups.media = lib.mkDefault { gid = 3000; };

        services.audiobookshelf = {
          enable = true;
          port = 8555;
          group = "media";
        };
      };
  };
}
