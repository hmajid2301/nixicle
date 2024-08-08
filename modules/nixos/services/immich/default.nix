{pkgs, ...}: let
  immichServer = {
    imageName = "ghcr.io/immich-app/immich-server";
    imageDigest = "sha256:61d965d477e720679b0746796ca245d8f5a38d10738a38bd8dca187dc5a0a6ac";
    sha256 = "sha256-rDgje7mcee/DZX1tE0HJNsswV1TCPdzvAzY16OLD5NY=";
  };

  immichMachineLearning = {
    imageName = "ghcr.io/immich-app/immich-machine-learning";
    imageDigest = "sha256:22fed1390a76262c582f42f81f4ac44f7c1e6ad525a013e526bf4b95534d5e93";
    sha256 = "sha256-TlQMq74y/pNh8/QBVnsiwphSlc+WJf/m1EmE5ba/dWw=";
  };

  dbHostname = "192.168.5.101"; # transfigured-night
  dbUsername = "immich";
  dbPassword = "immich";
  dbDatabaseName = "immich";

  redisHostname = "192.168.5.101"; # transfigured-night
  redisPassword = "hunter2";
  photosLocation = "/mnt/immich";

  immichWebUrl = "http://immich_web:3000";
  immichServerUrl = "http://immich_server:3001";
  immichMachineLearningUrl = "http://immich_machine_learning:3003";

  environment = {
    DB_HOSTNAME = dbHostname;
    DB_USERNAME = dbUsername;
    DB_PASSWORD = dbPassword;
    DB_DATABASE_NAME = dbDatabaseName;

    REDIS_HOSTNAME = redisHostname;
    REDIS_PASSWORD = redisPassword;

    UPLOAD_LOCATION = photosLocation;

    IMMICH_WEB_URL = immichWebUrl;
    IMMICH_SERVER_URL = immichServerUrl;
    IMMICH_MACHINE_LEARNING_URL = immichMachineLearningUrl;
  };

  wrapImage = {
    name,
    imageName,
    imageDigest,
    sha256,
    entrypoint,
  }:
    pkgs.dockerTools.buildImage {
      name = name;
      tag = "release";
      fromImage = pkgs.dockerTools.pullImage {
        imageName = imageName;
        imageDigest = imageDigest;
        sha256 = sha256;
      };
      created = "now";
      config =
        if builtins.length entrypoint == 0
        then null
        else {
          Cmd = entrypoint;
          WorkingDir = "/usr/src/app";
        };
    };
in {
  fileSystems."/mnt/immich" = {
    device = "192.168.5.6:/mnt/tank/immich";
    fsType = "nfs";
  };

  virtualisation.oci-containers.containers = {
    immich_server = {
      imageFile = wrapImage {
        inherit (immichServer) imageName imageDigest sha256;

        name = "immich_server";
        entrypoint = ["/bin/sh" "start-server.sh"];
      };
      image = "immich_server:release";
      extraOptions = ["--network=immich-bridge"];

      volumes = [
        "${photosLocation}:/usr/src/app/upload"
      ];

      environment = environment;

      ports = ["8084:3001"];

      autoStart = true;
    };

    immich_microservices = {
      imageFile = wrapImage {
        inherit (immichServer) imageName imageDigest sha256;

        name = "immich_microservices";
        entrypoint = ["/bin/sh" "start-microservices.sh"];
      };
      image = "immich_microservices:release";
      extraOptions = ["--network=immich-bridge"];

      volumes = [
        "${photosLocation}:/usr/src/app/upload"
      ];

      environment = environment;

      autoStart = true;
    };

    immich_machine_learning = {
      imageFile = pkgs.dockerTools.pullImage immichMachineLearning;
      image = "ghcr.io/immich-app/immich-machine-learning";
      extraOptions = ["--network=immich-bridge"];

      environment = environment;

      volumes = [
        "${photosLocation}:/usr/src/app/upload"
        "model-cache:/cache"
      ];

      autoStart = true;
    };
  };

  systemd.services.init-immich-network = {
    description = "Create the network bridge for immich.";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "oneshot";
    script = ''
      # Put a true at the end to prevent getting non-zero return code, which will
      # crash the whole service.
      check=$(${pkgs.docker}/bin/docker network ls | grep "immich-bridge" || true)
      if [ -z "$check" ];
        then ${pkgs.docker}/bin/docker network create immich-bridge
        else echo "immich-bridge already exists in docker"
      fi
    '';
  };

  services.nginx.virtualHosts."immich.service" = {
    locations."/" = {
      proxyPass = "http://localhost:8084";
      extraConfig = ''
        client_max_body_size 0;
        proxy_max_temp_file_size 96384m;
      '';
    };
  };
}
