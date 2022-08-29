# Defined in - @ line 1
function config --wraps='/usr/bin/git --git-dir=/home/haseeb/.cfg/ --work-tree=/home/haseeb' --description 'alias config=/usr/bin/git --git-dir=/home/haseeb/.cfg/ --work-tree=/home/haseeb'
  /usr/bin/git --git-dir=/home/haseeb/.cfg/ --work-tree=/home/haseeb $argv;
end
