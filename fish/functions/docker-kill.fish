# Defined in - @ line 1
function docker-kill --wraps='docker kill (docker ps -q)' --description 'alias docker-kill=docker kill (docker ps -q)'
  docker kill (docker ps -q) $argv;
end
