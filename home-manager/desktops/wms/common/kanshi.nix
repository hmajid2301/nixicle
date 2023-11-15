{ pkgs, ... }: {
  home.packages = with pkgs; [
    kanshi
  ];

  services.kanshi = {
    enable = true;
    package = pkgs.kanshi;
    systemdTarget = "";
    profiles = {
      undocked = {
        outputs = [
          {
            criteria = "eDP-1";
            scale = 1.0;
            status = "enable";
          }
        ];
      };
      home_office_laptop_docked = {
        outputs = [
          {
            criteria = "GIGA-BYTE TECHNOLOGY CO., LTD. Gigabyte M32U 21351B000087";
            position = "3840,0";
            mode = "3840x2160@144Hz";
          }
          {
            criteria = "Dell Inc. DELL G3223Q 82X70P3";
            position = "0,0";
            mode = "3840x2160@144Hz";
          }
          {
            criteria = "eDP-1";
            status = "disable";
          }
        ];
      };
      home_office = {
        outputs = [
          {
            criteria = "GIGA-BYTE TECHNOLOGY CO., LTD. Gigabyte M32U 21351B000087";
            position = "3840,0";
            mode = "3840x2160@144Hz";
          }
          {
            criteria = "Dell Inc. DELL G3223Q 82X70P3";
            position = "0,0";
            mode = "3840x2160@144Hz";
          }
        ];
      };
    };
  };
}
