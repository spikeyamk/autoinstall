#!/bin/bash

GITPATH=$(pwd)
source "$GITPATH"/config

# Configuring the system running everything in chroot
ln -sf /usr/share/zoneinfo/Europe/Bratislava /etc/localtime
hwclock --systohc



# Configuring and generating the locales
# sed -i '177s/.//' /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf



# Setting up networking and hostname
printf "Choose the hostname of the machine: "
read hostnm
echo "$hostnm" >> /etc/hostname
printf "127.0.0.1    localhost\n::1    localhost\n127.0.1.1    $hostnm.localdomain    $hostnm\n" >> /etc/hosts



# Configuring /etc/pacman.conf
sed -i '/ParallelDownloads = 5/s/^#//g' /etc/pacman.conf
printf "Do you wish to enable multilib? (support for 32-bit programs) [y/n]: "
read ANSWER
if [ "$ANSWER" == "y" ]
then
    sed -i '93s/.//' /etc/pacman.conf
    sed -i '94s/.//' /etc/pacman.conf
    printf "\e[1;32mMultilib repositories have been enabled\n\e[0m"
elif [ "$ANSWER" == "n" ]
then
    printf "Multilib repositories will stay disabled\n"
else
    printf "\e[1;31mError! Invalid answer\n\e[0m"
    exit
fi

pacman -Sy
pacman -S --noconfirm base-devel grub efibootmgr os-prober dosfstools mtools ntfs-3g networkmanager git vim wget reflector xorg xorg-xinit nitrogen pulseaudio pulseaudio-alsa pulseaudio-bluetooth pulseaudio-jack pavucontrol alsa-utils bluez bluez-utils p7zip htop btop lsscsi neofetch bash-completion samba openssh


# Setting root password
passwd



# Creating a user and giving it sudo privilleges
printf "Choose a username: "
read username
useradd -m "$username"
passwd "$username"
usermod -aG wheel,audio,video,optical,storage "$username"
sed -i '82s/.//' /etc/sudoers



# Installing GRUB bootloader and also some bloat
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
printf "Do you wish to integrate a win parition inside GRUB.conf [y/n]? :"
read answer

if [ "$answer" == "y" ] || [ "$answer" == "n" ]
then
	printf "%s\n" "$answer"
	if [ "$answer" == "y" ]
	then 
		printf "Specify the [WIN partition] PATH: "
		read WINPATH										      
		mkdir /home/"$username"/win
		mount "$WINPATH" /home/"$username"/win
		echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
	fi
else										  
    printf "\e[1;31mError! Invalid answer\n\e[0m"
	jumpto $start
fi

if [ "$UEFI_ENABLED" == "y" ]
then
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
elif [ "$UEFI_ENABLED" == "n" ]
then
    grub-install --target=i386-pc "$BIOSPATH"
    grub-mkconfig -o /boot/grub/grub.cfg
fi


# Installing xorg and configuring it + installing some GUI bloat
# nvidia-xconfig
# cp /etc/X11/xinit/xinitrc ~/.xinitrc



# Enabling system services and daemons with systemd
systemctl enable NetworkManager
printf "Do you use SSDs? [y/n]: "
read ANSWER
if [ "$ANSWER" == "y" ]
then
    systemctl enable fstrim.timer
    printf "\e[1;32mFstrim.timer has been enabled\n\e[0m"
elif [ "$ANSWER" == "n" ]
then
    printf "Fstrim.timer will stay disabled\n"
else
    printf "\e[1;31mError! Invalid answer\n\e[0m"
fi

# systemctl enable reflector.timer
# systemctl enable systemd-swap
# echo "vm.swappiness=10" >> /etc/sysctl.d/99-swappiness.conf
# echo "swapfc_enabled=1" >> /etc/systemd/swap.conf

printf "\e[1;32mDone! You can install additional software with pacman (see man pacman). Or you can type exit, then umount -a and reboot. The system is ready for a reboot.\n\e[0m"

exit
