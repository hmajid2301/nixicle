# Homepage settings configuration
# This file contains the settings and layout configuration for the homepage dashboard
{
  title = "Homelab Dashboard";
  favicon = "https://haseebmajid.dev/favicon.ico";
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
