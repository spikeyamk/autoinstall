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
					printf "Specify [EFI partition] PATH: "
					read EFIPATH
					printf "%s\n" "$EFIPATH"
					printf "Specify [ROOT partition] PATH: "
					read ROOTPATH
					printf "%s\n" "$ROOTPATH"		
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


# Base install starts
mount "$ROOTPATH" /mnt
pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab


# Chrooting
arch-chroot /mnt
