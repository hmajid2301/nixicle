# Defined in - @ line 1
function jwt --wraps=jq\ -R\ \'split\(\".\"\)\ \|\ .\[0\],.\[1\]\ \|\ @base64d\ \|\ fromjson\' --description alias\ jwt=jq\ -R\ \'split\(\".\"\)\ \|\ .\[0\],.\[1\]\ \|\ @base64d\ \|\ fromjson\'
  jq -R 'split(".") | .[0],.[1] | @base64d | fromjson' $argv;
end
