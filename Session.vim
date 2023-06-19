let SessionLoad = 1
let s:so_save = &g:so | let s:siso_save = &g:siso | setg so=0 siso=0 | setl so=-1 siso=-1
let v:this_session=expand("<sfile>:p")
silent only
silent tabonly
cd ~/dotfiles
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
let s:shortmess_save = &shortmess
if &shortmess =~ 'A'
  set shortmess=aoOA
else
  set shortmess=aoO
endif
badd +38 hosts/framework/default.nix
badd +31 README.md
badd +14 hosts/common/optional/quietboot.nix
badd +5 ~/dotfiles/home/haseeb/features/desktops/hyprland/rofi.nix
badd +19 ~/dotfiles/home/haseeb/features/desktops/hyprland/mako.nix
badd +61 ~/dotfiles/home/haseeb/features/desktops/hyprland/default.nix
badd +47 ~/dotfiles/home/haseeb/features/desktops/hyprland/swaylock.nix
badd +31 home/haseeb/features/gtk.nix
badd +13 ~/dotfiles/home/haseeb/features/fonts.nix
badd +1 ~/dotfiles/home/haseeb/fonts/default.nix
badd +1 ~/dotfiles/pkgs/default.nix
badd +8 ~/dotfiles/pkgs/fonts/default.nix
badd +1 ~/dotfiles/modules/home-manager/default.nix
badd +15 ~/dotfiles/home/haseeb/features/games/lutris.nix
badd +28 ~/dotfiles/home/haseeb/features/games/steam.nix
badd +5 ~/dotfiles/home/haseeb/features/games/default.nix
badd +127 home/haseeb/features/desktops/hyprland/waybar.nix
badd +12 hosts/common/global/locale.nix
badd +3 hosts/common/optional/pipewire.nix
badd +27 home/haseeb/features/programs/cli.nix
badd +4 ~/dotfiles/home/haseeb/features/programs/zoxide.nix
badd +2 ~/dotfiles/home/haseeb/features/programs/exa.nix
badd +2 ~/dotfiles/home/haseeb/features/programs/fzf.nix
badd +98 home/haseeb/features/programs/tmux.nix
badd +50 flake.nix
badd +27 hosts/framework/hardware-configuration.nix
badd +32 hosts/common/users/haseeb/default.nix
badd +1 ~/dotfiles/hosts/common/optional/fingerprint.nix
badd +26 ~/dotfiles/hosts/common/optional/backup.nix
badd +12 ~/dotfiles/hosts/common/global/nix.nix
badd +1 ~/dotfiles/hosts/common/optional/wireless.nix
badd +17 ~/dotfiles/home/haseeb/features/editors/nvim/default.nix
badd +28 home/haseeb/global/default.nix
badd +40 home/haseeb/features/programs/gpg.nix
badd +1 home/haseeb/features/programs/ssh.nix
badd +16 home/haseeb/features/browsers/firefox.nix
badd +9 home/haseeb/features/programs/git.nix
badd +7 home/haseeb/features/programs/bat.nix
badd +46 home/haseeb/features/desktops/hyprland/scripts/volume.sh
badd +22 hosts/common/optional/grub.nix
badd +14 ~/dotfiles/home/haseeb/framework.nix
badd +10 home/haseeb/features/editors/nvim/config/lua/plugins/tmux.lua
badd +17 home/haseeb/features/packages/other.nix
badd +1 ~/dotfiles/home/haseeb/features/editors/nvim/config/init.lua
badd +26 ~/dotfiles/home/haseeb/features/editors/nvim/config/lua/config/lazy.lua
argglobal
%argdel
edit hosts/framework/default.nix
let s:save_splitbelow = &splitbelow
let s:save_splitright = &splitright
set splitbelow splitright
let &splitbelow = s:save_splitbelow
let &splitright = s:save_splitright
wincmd t
let s:save_winminheight = &winminheight
let s:save_winminwidth = &winminwidth
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
argglobal
balt ~/dotfiles/home/haseeb/features/editors/nvim/config/lua/config/lazy.lua
let s:l = 38 - ((37 * winheight(0) + 37) / 74)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 38
normal! 0
tabnext 1
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0 && getbufvar(s:wipebuf, '&buftype') isnot# 'terminal'
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20
let &shortmess = s:shortmess_save
let &winminheight = s:save_winminheight
let &winminwidth = s:save_winminwidth
let s:sx = expand("<sfile>:p:r")."x.vim"
if filereadable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &g:so = s:so_save | let &g:siso = s:siso_save
nohlsearch
let g:this_session = v:this_session
let g:this_obsession = v:this_session
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
