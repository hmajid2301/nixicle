# Homepage settings configuration
# This file contains the settings and layout configuration for the homepage dashboard
{ lib }:

{
  title = "Homelab Dashboard";
  favicon = "https://homepage.${lib.nixicle.domains.root}/icons/favicon.svg";
  headerStyle = "clean";
  theme = "dark";
  color = "slate";
  layout = {
    external = {
      style = "row";
      columns = 3;
    };
    internal = {
      style = "row";
      columns = 3;
    };
    monitoring = {
      style = "row";
      columns = 2;
    };
    network = {
      style = "row";
      columns = 2;
    };
  };
}
