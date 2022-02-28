#!/bin/bash

GITPATH=$(pwd)

# Enabling the AUR
git clone https://aur.archlinux.org/yay
cd yay
makepkg -si


# sudo pacman -S --noconfirm nvidia nvidia-utils lib32-nvidia-utils nvidia-settings
# Installing additional bloat
yay -S spotify
# sudo nvidia-xconfig
cp /etc/X11/xinit/xinitrc ~/.xinitrc



# Installing the suckless utilities
git clone https://www.github.com/spikeyamk/st-spikeyamk
cd st-spikeyamk
makepkg -si


git clone https://www.github.com/spikeyamk/dwm-spikeyamk
cd dwm-spikeyamk
makepkg -si
cp "$GITPATH"/xinitrc ~/.xinitrc


git clone https://www.github.com/spikeyamk/dwmblocks-spikeyamk
cd dwmblocks-spikeyamk
makepkg -si

