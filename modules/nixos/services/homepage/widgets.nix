# Homepage widget definitions
# This file contains all the widget configurations for the homepage dashboard
[
  {
    search = {
      provider = "custom";
      url = "https://kagi.com/search?q=";
      target = "_blank";
      suggestionUrl = "https://kagi.com/autocomplete?type=list&q=";
      showSearchSuggestions = true;
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
    resources = {
      label = "storage";
      disk = ["/mnt/n1/"];
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
