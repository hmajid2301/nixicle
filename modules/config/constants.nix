{delib, ...}:
delib.module {
  name = "constants";

  options = with delib; {
    username = readOnly (strOption "haseeb");
    userfullname = readOnly (strOption "Haseeb Majid");
    useremail = readOnly (strOption "hello@haseebmajid.dev");
  };
}
