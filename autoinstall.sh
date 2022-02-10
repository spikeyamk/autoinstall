#!/bin/bash

GITPATH=$(pwd)
UEFI_ENABLED=n
SECURE_BOOT_ENABLED=n

source "$GITPATH"/uefi.sh
source "$GITPATH"/bios.sh

# Jumpto function definition
function jumpto
{
	label=$1
	cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$') 
	eval "$cmd"
	exit
}

# Install lsscsi
pacman -S --noconfirm lsscsi


# Activating ntp time synchronization
timedatectl set-ntp true


# Enabling parallel downloads in /etc/pacman.conf
sed -i '/ParallelDownloads = 5/s/^#//g' /etc/pacman.conf


# Script jumptos here after an invalid answer to start over again
start=${1:-"start"}
start:


# Configuring the installer for legacy BIOS or UEFI boot
printf "1> For UEFI systems\n2> For UEFI systems with SecureBoot\n3> For legacy BIOS systems\nSelect the boot mode [1/2/3]: "
read BOOTMODE

if [ "$BOOTMODE" == "1" ]
then
	UEFI_ENABLED=$(bootctl | awk 'NR==2' | sed 's/    //')
	if [ "$UEFI_ENABLED" ==  "Not booted with EFI" ]
	then
		printf "\e[1;31mError! Legacy BIOS boot mode is enabled. Reboot into the UEFI firmware settings, enable it and boot into the live Archiso environment in the UEFI mode\n\e[0m"
		printf "Exiting the script!\n"
		exit
	else
		printf "\e[1;32mUEFI Firmware detected!\n\e[0m"
		printf "\e[1;32m$UEFI_ENABLED\n\e[0m"
		UEFI_ENABLED=y
		uefipart
	fi
elif [ "$BOOTMODE" == "2" ]
then
	printf "UEFI with SecureBoot has not been implemented yet.\n"
	UEFI_ENABLED=$(bootctl | awk 'NR==2' | sed 's/    //')
	if [ "$UEFI_ENABLED" ==  "Not booted with EFI" ]
	then
		printf "\e[1;31mError! Legacy BIOS boot mode is enabled. Reboot into the UEFI firmware settings, enable it and boot into the live Archiso environment in the UEFI mode\n\e[0m"
		printf "Exiting the script!\n"
		exit
	else
		printf "\e[1;32mUEFI Firmware detected!\n\e[0m"
		printf "\e[1;32m$UEFI_ENABLED\n\e[0m"
		UEFI_ENABLED=y
		SECURE_BOOT_ENABLED=y
		uefipart
	fi
elif [ "$BOOTMODE" == "3" ]
then
	UEFI_ENABLED=n
	biospart
else										  
	printf '\e[31m%s\e[0m' "Error! Invalid answer\n"
	jumpto $start
fi





# Saving variables to config
printf "Variables you chose:\n" >> config
printf "+++++++++++++++++++++++++++++\n" >> config
printf "GITPATH=$GITPATH\n" >> config
printf "UEFI_ENABLED=$UEFI_ENABLED\n" >> config
printf "SECURE_BOOT_ENABLED=$SECURE_BOOT_ENABLED\n" >> config
printf "BOOTMODE=$BOOTMODE\n" >> config
printf "AUTOPART=$AUTOPART\n" >> config
printf "DISKTOAUTOPART=$DISKTOAUTOPART\n" >> config
printf "USESWAP=$USESWAP\n" >> config
printf "SWAPSIZE=$SWAPSIZE\n" >> config
printf "DISKTOPART=$DISKTOPART\n" >> config
printf "BIOSPATH=$BIOSPATH\n" >> config
printf "EFIPATH=$EFIPATH\n" >> config
printf "SWAPPATH=$SWAPPATH\n" >> config
printf "ROOTPATH=$ROOTPATH\n" >> config
printf "+++++++++++++++++++++++++++++\n" >> config


# Printing the variables
printf "Variables you chose:\n"
printf "+++++++++++++++++++++++++++++\n"
printf "GITPATH=$GITPATH\n"
printf "UEFI_ENABLED=$UEFI_ENABLED\n"
printf "SECURE_BOOT_ENABLED=$SECURE_BOOT_ENABLED\n"
printf "BOOTMODE=$BOOTMODE\n"
printf "AUTOPART=$AUTOPART\n"
printf "DISKTOAUTOPART=$DISKTOAUTOPART\n"
printf "USESWAP=$USESWAP\n"
printf "SWAPSIZE=$SWAPSIZE\n"
printf "DISKTOPART=$DISKTOPART\n"
printf "BIOSPATH=$BIOSPATH\n"
printf "EFIPATH=$EFIPATH\n"
printf "SWAPPATH=$SWAPPATH\n"
printf "ROOTPATH=$ROOTPATH\n"
printf "+++++++++++++++++++++++++++++\n"


# Base pacstrap installation
printf "Everything OK? [y/n]: "
read ANSWER
if [ "$ANSWER" == "y" ]
then
	# Installing the base
	pacstrap /mnt base linux linux-firmware
	genfstab -U /mnt >> /mnt/etc/fstab

	printf "\e[1;32mSuccess!\n\e[0m"
	printf "\e[1;32mDo you wish to chroot into your newly installed Arch Linux base and continue the installation? [y/n]: \e[0m"
	read ANSWER
	if [ "$ANSWER" == "y" ]
	then
		# Chrooting
		cp -a /root/autoinstall /mnt
		printf "Chrooting into /mnt"
		sleep 1
		printf "."
		sleep 1
		printf "."
		sleep 1
		printf ".\n"
		arch-chroot /mnt
	elif [ "$ANSWER" == "n" ]
	then
		printf "Exiting the script!\n"
		exit
	else
        printf "\e[1;31mError! Invalid answer\n\e[0m"
		exit
    fi
elif [ "$ANSWER" == "n" ]
then
	printf "Exiting the script!\n"
	exit
else
	printf "\e[1;31mError! Invalid answer\n\e[0m"
	jumpto $start
fi
