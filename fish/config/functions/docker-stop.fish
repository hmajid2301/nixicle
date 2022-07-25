# Defined in - @ line 1
function docker-stop --wraps='docker stop (docker ps -a -q)' --description 'alias docker-stop=docker stop (docker ps -a -q)'
  docker stop (docker ps -a -q) $argv;
end
