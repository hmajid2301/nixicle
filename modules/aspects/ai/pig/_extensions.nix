{
  buildGoModule,
  extensionNames,
}:
buildGoModule {
  pname = "pig-extensions";
  version = "0.1.0";

  src = ./extensions;

  subPackages = map (n: "cmd/${n}") extensionNames;

  env.CGO_ENABLED = "0";

  vendorHash = "sha256-rh32/chbY7whB+3y/2Jtcy5iLMkbBKm/RYqYNXMryO0=";
}
