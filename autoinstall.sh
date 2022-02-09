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


# Script jumptos here after an invalid answer to start over again
start=${1:-"start"}
start:


# Configuring the installer for legacy BIOS or UEFI boot
printf "1- For UEFI systems\n2- For legacy BIOS systems\nSelect the boot mode [1/2]: "
read BOOTMODE
printf "%s\n" "$BOOTMODE"
if [ "$BOOTMODE" == "1" ] || [ "$BOOTMODE" == "2" ]
then
	printf "%s\n" "$BOOTMODE"
	if [ "$BOOTMODE" == "2" ]
		then
			printf "Legacy BIOS has not been implemented yet.\n"
			exit
	fi
else										  
	printf "Error! Invalid answer\n"
	jumpto $start
fi


# Suggested auto partitioning
printf "Do you wish to use suggested auto partitiong of the drives? [y/n]: "
read ANSWER
if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "n" ]
then
	printf "%s\n" "$ANSWER"
	if [ "$ANSWER" == "y" ]
		then 
			printf "Suggested auto partitiong has not been implemented yet.\n"
			exit
		else
			printf "Have you partitioned the disk yourself already? [y/n]: "
			read ANSWER
			if [ "$ANSWER" == "y" ]
				then
					# Getiing the partition paths
					fdisk -l
					printf "Specify [EFI System] PATH: "
					read EFIPATH
					printf "%s\n" "$EFIPATH"
					printf "Specify [Linux filesystem(root)] PATH: "
					read ROOTPATH
					printf "%s\n" "$ROOTPATH"	
					printf "Specify [Linux swap] PATH (leave blank if you do not wish to use a swap partition): "
					read SWAPPATH	
				else
					printf "You can use the fdisk command line utility (see man fdisk (8)) to partition the disks and then rerun the script.\n"
					cat partitiontable.txt
					exit
			fi
	fi
else										  
	printf "Error! Invalid answer\n"
	jumpto $start
fi



# Formatting the partitions
mkfs.fat -F 32 "$EFIPATH"
mkfs.ext4 "$ROOTPATH"
mkswap "$SWAPPATH"

# Base install starts
mount "$ROOTPATH" /mnt
mkdir /mnt/boot
mount "$EFIPATH" /mnt/boot
swapon "$SWAPPATH"
pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab


# Chrooting
arch-chroot /mnt
