# Defined in - @ line 1
function docker-rm --wraps='docker rm (docker ps -a -q)' --description 'alias docker-rm=docker rm (docker ps -a -q)'
  docker rm (docker ps -a -q) $argv;
end
