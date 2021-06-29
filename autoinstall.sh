#!/bin/bash

# Getiing the partition paths and formatting the partitions
echo -n "Specify [EFI partition] PATH: "
read EFIPATH
printf "%s\n" "$EFIPATH"
echo -n "Specify [ROOT partition] PATH: "
read ROOTPATH
printf "%s\n" "$ROOTPATH"

mkfs.fat -F 32 "$EFIPATH"
mkfs.ext4 "$ROOTPATH"



# Base install starts
mount "$ROOTPATH" /mnt
pacstrap /mnt base linux linux-firmware base-devel



#Configuring the system
genfstab -U /mnt >> /mnt/etc/genfstab
arch-chroot /mnt
pacman -Sy
pacman -S vim sudo
ln -sf /usr/share/zoneinfo/Europe/Bratislava /etc/localtime
hwclock --systohc



# Configuring and generating the locales
sed -i '177s/.//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf



# Setting up networking and hostname
printf "Choose your hostname: "
read hostnm
echo "$hostnm" > /etc/hostname
printf "127.0.0.1    localhost\n::1    localhost\n127.0.1.1    %s.localdomain    %s" "$hostnm, $hostnm" > /etc/hosts



# Setting passwords and creating users
passwd
printf "Choose a username: "
read username
useradd -m "$username"
passwd "$username"
usermod -aG wheel,video,optical,storage "$username"
sed -i '82s/.//' /etc/sudoers



# Installing GRUB bootloader
mkdir /mnt/EFI
mount "$EFIPATH" /mnt/EFI
pacman -S grub efibootmgr os-prober dosfstools ntfs-3g networkmanager git

TEST=$(grep -i vendor_id /proc/cpuinfo | sed '1,2d' | awk '{print $NF }')
printf "%s\n" "$TEST"

if [ "$TEST" = "GenuineIntel" ];
		pacman -S intel-ucode
	else 
		pacman -S amd-ucode
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
	fi
else										  
	printf "Error! Unvalid character\n"
	jumpto $start
fi

grub-install --target=x86_64-efi --efi-directory=/mnt/EFI --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg



# Enabling system services and daemons with systemd
systemctl enable NetworkManager
systemctl enable fstrim.timer

exit

echo "Do you wish to reboot [y/n]?"
read ans
if [ "$ans" == "y" ]
then
	umount -R /mnt
	reboot
fi







