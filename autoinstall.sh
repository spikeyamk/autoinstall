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
read AUTOPART

if [ "$AUTOPART" == "y" ] || [ "$AUTOPART" == "n" ]
then
	printf "%s\n" "$AUTOPART"
	if [ "$AUTOPART" == "y" ]
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
			TEST=$(find "$EFIPATH")
			if [ "$TEST" != "$EFIPATH" ]
			then
				printf "Error! Specified EFI partition does not exist"
				jumpto $start
				exit
			fi
			
			TEST=$(find "$EFIPATH" | sed 's/[0-9]//' | fdisk -l | grep "$EFIPATH" | sed 's/[^ ]* *//' | sed 's/[^ ]* *//' | sed 's/[^ ]* *//' | sed 's/[^ ]* *//' | sed 's/[^ ]* *//')
			if [ "$TEST" != "EFI System" ]
			then
				printf "Error! Specified EFI parition is not the correct partition type"
				exit
			fi
		
			
			TEST=$(find "$EFIPATH" | sed 's/\/dev\///' | lsblk -b | awk '{ print $4 }')
			TEST=$(printf "%d" "$EFIPATH")
			if [[ $TEST -lt 314572800 ]]
			then
				printf "The EFI partition is too small. Increase its size. $TEST\n"
				sleep 5
				exit
			fi	

			printf "Specify [Linux swap] PATH (leave blank if you do not wish to use a swap partition): "
			read SWAPPATH
			TEST=$(find "$SWAPPATH")
			if [ "$TEST" != "$SWAPPATH" ]
			then
				exit
			fi
				
			
			printf "Specify [Linux filesystem(root)] PATH: "
			read ROOTPATH
			printf "%s\n" "$ROOTPATH"
			TEST=$(find "$ROOTPATH")
			if [ "$TEST" != "$ROOTPATH" ]
			then
				exit
			fi
				
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
printf "Following partitions will be formatted: %s, %s, %s\n" "$EFIPATH $ROOTPATH $SWAPPATH"
printf "All data on them will be permanently erased. Do you wish to proceed? [y/n]: "

read ANSWER
if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "n" ]
then
	if [ "$ANSWER" == "y" ]
	then
		mkfs.fat -F 32 "$EFIPATH"
		mkfs.ext4 "$ROOTPATH"
		mkswap "$SWAPPATH"
	elif [ "$ANSWER" == "n" ]
	then
		printf "Exiting the script!\n"
		exit
	fi
else
	printf "Error! Invalid answer\n"
		jumpto $start
fi

# Mounting the filesystems
mount "$ROOTPATH" /mnt
mkdir /mnt/boot
mount "$EFIPATH" /mnt/boot
swapon "$SWAPPATH"


pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab


# Chrooting
arch-chroot /mnt
