#!/bin/bash

echo -n "Specify [EFI partition] PATH: ";
read EFIPATH;
printf "%s\n" "$EFIPATH";

echo -n "Specify [ROOT partition] PATH: ";
read ROOTPATH;
printf "%s\n" "$ROOTPATH";

mkfs.fat -F 32 "$EFIPATH";
mkfs.ext4 "$ROOTPATH";
mount "$ROOTPATH" /mnt;

pacstrap /mnt base linux linux-firmware base-devel;

genfstab -U /mnt >> /mnt/etc/genfstab

arch-chroot /mnt;

pacman -Sy

pacman -S vim sudo;

ln -sf /usr/share/zoneinfo/Europe/Bratislava /etc/localtime;

hwclock --systohc

locale-gen plz help
./uncomment.sh


	echo "LANG=en_US.UTF-8" > /etc/locale.conf

	printf "Choose your hostname: ";
	read hostnm
	echo "$hostnm" > /etc/hostname

	rm /etc/hosts
	printf "127.0.0.1    localhost\n::1    localhost\n127.0.1.1    %s.localdomain    %s" "$hostnm, $hostnm"

passwd

./useradd.sh

visudo plz help men

mkdir /mnt/EFI

mount "$EFIPATH" /mnt/EFI

pacman -S grub efibootmgr os-prober dosfstools ntfs-3g networkmanager git

./cpuinfo.sh

./windows.sh

grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager

exit

umount -R /mnt

reboot







