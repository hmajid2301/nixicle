[
  {
    search = {
      provider = "custom";
      url = "https://kagi.com/search?q=";
      target = "_blank";
    };
  }
  {
    resources = {
      label = "system";
      cpu = true;
      memory = true;
    };
  }
  {
    openmeteo = {
      label = "London";
      timezone = "Europe/London";
      latitude = "{{HOMEPAGE_VAR_LATITUDE}}";
      longitude = "{{HOMEPAGE_VAR_LONGITUDE}}";
      units = "metric";
    };
  }
]
