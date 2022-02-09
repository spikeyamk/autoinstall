#!/bin/bash

# Jumpto function definition
function jumpto
{
	label=$1
	cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$') 
	eval "$cmd"
	exit
}


# Activating ntp time synchronization
timedatectl set-ntp true


# Enabling parallel downloads in /etc/pacman.conf
sed -i '/ParallelDownloads = 5/s/^#//g' /etc/pacman.conf


# Configuring the installer for legacy BIOS or UEFI boot
bootmodesel=${1:-"start"}
bootmodesel:

printf "1- For UEFI systems\n2- For legacy BIOS systems\n Select the boot mode [1/2]: "
read BOOTMODE
printf "%s\n" "$BOOTMODE"
if [ "$BOOTMODE" == "1" ] || [ "$BOOTMODE" == "2" ]
then
	printf "%s\n" "$BOOTMODE"
else										  
	printf "Error! Invalid answer\n"
	jumpto $bootmodesel
fi


# Suggested auto partitioning
autopart=${1:-"start"}
autopart:

printf "Do you wish to use suggested auto partitiong of the drives? [y/n]: "
read ANSWER
if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "n" ]
then
	printf "%s\n" "$ANSWER"
	if [ "$ANSWER" == "y" ]
		then 
			printf "success"
		else
			printf "nosuccess"
	fi
else										  
	printf "Error! Invalid answer\n"
	jumpto $autopart
fi



# Getiing the partition paths
printf "Specify [EFI partition] PATH: "
read EFIPATH
printf "%s\n" "$EFIPATH"
printf "Specify [ROOT partition] PATH: "
read ROOTPATH
printf "%s\n" "$ROOTPATH"


# Formatting the partitions
mkfs.fat -F 32 "$EFIPATH"
mkfs.ext4 "$ROOTPATH"


# Base install starts
mount "$ROOTPATH" /mnt
pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab


# Chrooting
arch-chroot /mnt
