{ ... }:
{
  den.aspects.invidious = {
    includes = [ ];

    nixos =
      { ... }:
      {
        services.invidious = {
          enable = true;
          port = 3939;
          address = "127.0.0.1";
          database.createLocally = true;
          settings = {
            db.user = "invidious";
            registration_enabled = false;
            statistics_enabled = false;
            popular_enabled = false;
            use_pubsub_feeds = false;
            external_port = 443;
            https_only = true;
          };
        };
      };
  };
}
