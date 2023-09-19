{ pkgs, ... }: {

  home.packages = with pkgs; [
    foliate
  ];

  # TODO: fetch file from github: https://github.com/catppuccin/foliate/blob/main/themes.json
  xdg.configFile."com.github.johnfactotum.Foliate/themes.json".text =
    # json
    ''
      {
      	"themes": [
      		{
      			"theme-name": "Catppuccin Mocha",
      			"fg-color": "rgb(205,214,244)",
      			"bg-color": "rgb(30,30,46)",
      			"link-color": "rgb(245, 224, 220)",
      			"invert": true,
      			"dark-mode": true
      		},
      		{
      			"theme-name": "Catppuccin Macchiato",
      			"fg-color": "rgb(202, 211, 245)",
      			"bg-color": "rgb(36, 39, 58)",
      			"link-color": "rgb(244, 219, 214)",
      			"invert": true,
      			"dark-mode": true
      		},
      		{
      			"theme-name": "Catppuccin Frappe",
      			"fg-color": "rgb(198, 208, 245)",
      			"bg-color": "rgb(48, 52, 70)",
      			"link-color": "rgb(242, 213, 207)",
      			"invert": true,
      			"dark-mode": true
      		},
      		{
      			"theme-name": "Catppuccin Latte",
      			"fg-color": "rgb(76, 79, 105)",
      			"bg-color": "rgb(239, 241, 245)",
      			"link-color": "rgb(220, 138, 120)",
      			"invert": false,
      			"dark-mode": false
      		}
      	]
      }
    '';
}
