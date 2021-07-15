#!/bin/bash

# Enabling the AUR
sudo pacman -S base-devel
git clone https://aur.archlinux.org/paru
cd paru 
makepkg -si



# Installing additional bloat
paru -S brave-bin spotify nerd-fonts-ubuntu-mono
sudo nvidia-xconfig
cp /etc/X11/xinit/xinitrc ~/.xinitrc



# Installing the suckless utilities
git clone https://www.github.com/spikeyamk/st
cd st
sudo make clean install

git clone https://www.github.com/spikeyamk/dwm
cd dwm
sudo make clean install

git clone https://www.github.com/spikeyamk/dwmblocks
cd dwmblocks
sudo make clean install
