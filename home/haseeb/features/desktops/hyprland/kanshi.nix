{...}: {
 services.kanshi = {
    enable = true;
    profiles = {
      undocked = {
        outputs = [
          {
            criteria = "eDP-1";
            scale = 2.0;
          }
        ];
      };
      home_office = {
        outputs = [
          {
            criteria = "GIGA-BYTE TECHNOLOGY CO., LTD. Gigabyte M32U 21351B000087 ";
            position = "3840,0";
            mode = "3840x2160@60Hz";
          }
          {
            criteria = "Dell Inc. DELL G3223Q 82X70P3";
            position = "0,0";
            mode = "3840x2160@60Hz";
          }
          {
            criteria = "eDP-1";
            status = "disable";
          }
        ];
      };
    };
  };
}
