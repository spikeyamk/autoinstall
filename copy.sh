#!/bin/bash

# Configuring the system running everything in chroot
ln -sf /usr/share/zoneinfo/Europe/Bratislava /etc/localtime
hwclock --systohc



# Configuring and generating the locales
sed -i '177s/.//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf



# Setting up networking and hostname
printf "Choose your hostname: "
read hostnm
echo "$hostnm" >> /etc/hostname
printf "127.0.0.1    localhost\n::1    localhost\n127.0.1.1    %s.localdomain    %s" "$hostnm, $hostnm" >> /etc/hosts



# Enabling 32-bit pacman repositories
sed -i '93s/.//' /etc/pacman.conf
sed -i '94s/.//' /etc/pacman.conf
pacman -Sy



# Setting root password
passwd



# Creating a user and giving it sudo privilleges
printf "Choose a username: "
read username
useradd -m "$username"
passwd "$username"
usermod -aG wheel,video,optical,storage "$username"
pacman -S --noconfirm sudo
sed -i '82s/.//' /etc/sudoers



# Installing GRUB bootloader and also some bloat + dGPU drivers 
mkdir /mnt/EFI
echo -n "Specify [EFI partition] PATH: "
read EFIPATH
mount "$EFIPATH" /mnt/EFI
pacman -S --noconfirm grub efibootmgr os-prober dosfstools ntfs-3g networkmanager git vim wget reflector nvidia nvidia-utils lib32-nvidia-utils nvidia-settings
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

TEST=$(grep -i vendor_id /proc/cpuinfo | sed -n '$p' | awk '{print $NF }')
printf "%s\n" "$TEST"

if [ "$TEST" = "GenuineIntel" ]
	then
		pacman -S --noconfirm intel-ucode
	else 
		pacman -S --noconfirm amd-ucode
fi

function jumpto
{
	label=$1
	cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$') 
	eval "$cmd"
	exit
}

start=${1:-"start"}
start:
printf "Do you wish to integrate a win parition inside GRUB.conf [y/n]? ;"
read answer

if [ "$answer" == "y" ] || [ "$answer" == "n" ]
then
	printf "%s\n" "$answer"
	if [ "$answer" == "y" ]
	then 
		printf "Specify the [WIN partition] path: "
		read WINPATH										      
		mkdir /home/"$username"/win
		mount "$WINPATH" /home/"$username"/win
		echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
	fi
else										  
	printf "Error! Unvalid character\n"
	jumpto $start
fi

grub-install --target=x86_64-efi --efi-directory=/mnt/EFI --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg



# Installing xorg and configuring it + installing some GUI bloat
pacman -S --noconfirm xorg xorg-xinit nitrogen pulseaudio systemd-swap rofi pcmanfm pavucontrol p7zip picom htop
nvidia-xconfig
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



# Enabling system services and daemons with systemd
systemctl enable NetworkManager
systemctl enable fstrim.timer
systemctl enable fstrim.service
# systemctl enable reflector.timer
systemctl enable systemd-swap
echo "vm.swappiness=10" > /etc/sysctl.d/99-swappiness.conf

printf "\e[1;32mDone! Type umount -a and reboot.\e[0m"

exit
