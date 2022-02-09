#!/bin/bash

UEFI_ENABLED=n
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
		# Suggested auto partitioning
        printf "Do you wish to use suggested auto partitioning of the drives? [y/n]: "
        read AUTOPART
        if [ "$AUTOPART" == "y" ]
        then
            printf "Available disks for installation\n"
            lsscsi | grep disk | nl -w2 -s'> '
            printf "Which disk would you like to auto parition? [choose a number 1, 2, 3 etc.]: "
            read DISKTOAUTOPART
            DISKTOAUTOPART=$(lsscsi | grep disk | sed -n $((DISKTOAUTOPART))p | awk '{print $(NF)}')

            # DISKTOAUTOPART test
            TEST=$(find $DISKTOAUTOPART)
        if [ "$DISKTOAUTOPART" == "$TEST" ]
        then
            printf "Do you wish to create a swap partition? [y/n]: "
            read USESWAP
            if [ "$USESWAP" == "y" ]
            then
                printf "Choose the size of the swap partition in GiB (example 4 chooses 4 GiB): "
                read SWAPSIZE
                printf "\e[1;31mWARNING! All data on the %s will be erased\n\e[0m"
                printf "Do you wish to proceed? [y/n]: "
                read ANSWER
                if [ "$ANSWER" == "y" ]
                then
                    (
                    echo g;
                    echo n;
                    echo 1;
                    echo ;
                    echo +300M;
                    echo n;
                    echo 2;
                    echo ;
                    echo +"$SWAPSIZE"G;
                    echo n;
                    echo 3;
                    echo ;
                    echo ;
                    echo t;
                    echo 1;
                    echo 1;
                    echo t;
                    echo 2;
                    echo 19;
                    echo w;
                    ) | fdisk $DISKTOAUTOPART
                    EFIPATH="$DISKTOAUTOPART""1"
                    SWAPPATH="$DISKTOAUTOPART""2"
                    ROOTPATH="$DISKTOAUTOPART""3"
                elif [ "$ANSWER" == "n" ]
                    then
                    printf "Exiting the script!\n"
                    exit
                else
                    printf "\e[1;31mError! Invalid answer\n\e[0m"
                    jumpto $start
                fi
            elif [ "$USESWAP" == "n" ]
            then
                printf "\e[1;31mWARNING! All data on the %s will be erased\n\e[0m" "$DISKTOPART"
                printf "Do you wish to proceed? [y/n]: "
                read ANSWER
                if [ "$ANSWER" == "y" ]
                then
                    (
                        echo g;
                        echo n;
                        echo 1;
                        echo ;
                        echo +300M;
                        echo n;
                        echo 2;
                        echo ;
                        echo ;
                        echo t;
                        echo 1;
                        echo 1;
                        echo w;
                    ) | fdisk $DISKTOAUTOPART
                    EFIPATH="$DISKTOAUTOPART""1"
                    ROOTPATH="$DISKTOAUTOPART""2"
                elif [ "$ANSWER" == "n" ]
                then
                    printf "Exiting the script!\n"
                    exit
                else
                    printf "\e[1;31mError! Invalid answer\n\e[0m"
                    jumpto $start
                fi
            else
                printf "\e[1;31mError! Invalid answer\n\e[0m"
                jumpto $start
            fi
        else
            printf "\e[1;31mError! Invalid answer\n\e[0m"
            jumpto $start
        fi




    elif [ "$AUTOPART" == "n" ]
    then
        # Manual partitioning
        printf "Have you partitioned the disk yourself already? [y/n]: "
        read ANSWER
        if [ "$ANSWER" == "y" ]
        then
            # Getiing the partition paths
            fdisk -l
            printf "Specify [EFI System] PATH: "
            read EFIPATH
            printf "%s\n" "$EFIPATH"


            # EFI Partition tests
            ###
            TEST=$(find "$EFIPATH")
            if [ "$TEST" != "$EFIPATH" ]
            then
                printf "\e[1;31mError! Specified EFI partition does not exist\n\e[0m"
                jumpto $start
            fi
            # EFI partition type test
            TEST=$(find "$EFIPATH" | sed 's/[0-9]//' | fdisk -l | grep "$EFIPATH" | sed 's/[^ ]* *//' | sed 's/[^ ]* *//' | sed 's/[^ ]* *//' | sed 's/[^ ]* *//' | sed 's/[^ ]* *//')
            if [ "$TEST" != "EFI System" ]
            then
                printf "\e[1;31mError! Specified EFI parition is not the correct partition type\n\e[0m"
                jumpto $start
            fi
            #EFI partition size test
            TEST=$(lsblk -b "$EFIPATH" | awk '{print $4}' | awk 'NR==2')
            if [[ $((TEST)) -lt 314572800 ]]
            then
                printf "\e[1;31mError! The EFI partition is too small. Its size has to be at least 300 MiB.\n\e[0m"
                exit
            fi
            ###
            # End of EFI partition tests


            ###
            # Swap partition tests
            printf "Do you wish to use a linux swap partition? [y/n]: "
            read USESWAP
            if [ "$USESWAP" == "y" ]
            then
                printf "Specify the linux swap partition [Linux swap] PATH: "
                read SWAPPATH
                TEST=$(find "$SWAPPATH")
                if [ "$TEST" != "$SWAPPATH" ]
                then
                    printf "\e[1;31mError! Specified swap partition does not exist\n\e[0m"
                    jumpto $start
                fi

                # Linux swap partition type test
                TEST=$(find "$SWAPPATH" | sed 's/[0-9]//' | fdisk -l | grep "$SWAPPATH" | sed 's/[^ ]* *//' | sed 's/[^ ]* *//' | sed 's/[^ ]* *//' | sed 's/[^ ]* *//' | sed 's/[^ ]* *//')
                if [ "$TEST" != "Linux swap" ]
                then
				printf "\e[1;31mError! Specified Linux swap parition is not the correct partition type\n\e[0m"
                    jumpto $start
                fi
                # End of swap partition tests
                ###


                ###
                # Linux root filesystem tests
                printf "Specify [Linux filesystem(root)] PATH: "
                read ROOTPATH

                printf "%s\n" "$ROOTPATH"
                TEST=$(find "$ROOTPATH")
                if [ "$TEST" != "$ROOTPATH" ]
                then
                    printf "\e[1;31mError! Specified Linux root parition does not exist\n\e[0m"
                    jumpto $start
                fi
                # Linux root filesystem partition type test
                TEST=$(find "$ROOTPATH" | sed 's/[0-9]//' | fdisk -l | grep "$ROOTPATH" | sed 's/[^ ]* *//' | sed 's/[^ ]* *//' | sed 's/[^ ]* *//' | sed 's/[^ ]* *//' | sed 's/[^ ]* *//')
                if [ "$TEST" != "Linux filesystem" ]
                then
                    printf "\e[1;31mError! Specified Linux root parition is not the correct partition type\n\e[0m"
                    jumpto $start
                fi
                # End of Linux root filesystem tests
                ###

            elif [ "$USESWAP" == "n" ]
            then
                ###
                # Linux root filesystem tests
                printf "Specify [Linux filesystem(root)] PATH: "
                read ROOTPATH

                printf "%s\n" "$ROOTPATH"
                TEST=$(find "$ROOTPATH")
                if [ "$TEST" != "$ROOTPATH" ]
                then
                    printf "\e[1;31mError! Specified Linux root parition does not exist\n\e[0m"
                    jumpto $start
                fi
                # Linux root filesystem partition type test
                TEST=$(find "$ROOTPATH" | sed 's/[0-9]//' | fdisk -l | grep "$ROOTPATH" | sed 's/[^ ]* *//' | sed 's/[^ ]* *//' | sed 's/[^ ]* *//' | sed 's/[^ ]* *//' | sed 's/[^ ]* *//')
                if [ "$TEST" != "Linux filesystem" ]
                then
                    printf "\e[1;31mError! Specified Linux root parition is not the correct partition type\n\e[0m"
                    jumpto $start
                fi
                # End of Linux root filesystem tests
                ###
            else
                printf "\e[1;31mError! Invalid answer\n\e[0m"
                jumpto $start
            fi
        elif [ "$ANSWER" == "n" ]
        then
            printf "You can use the fdisk command line utility (see man fdisk) to partition the disks and then rerun the script.\n"
            cat partitiontable.txt
            exit
        else
            printf "\e[1;31mError! Invalid answer\n\e[0m"
            jumpto $start
            fi
        else
            printf "\e[1;31mError! Invalid answer\n\e[0m"
            jumpto $start
        fi



        # Formatting the partitions
        printf "\e[1;31mWARNING! Following partitions will be formatted: $EFIPATH, $SWAPPATH, $ROOTPATH\n\e[0m"
        printf "\e[1;31mAll data on them will be permanently erased. Do you wish to proceed? [y/n]: \e[0m"

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
            printf "\e[1;31mError! Invalid answer\n\e[0m"
            jumpto $start
        fi

        # Mounting the filesystems
        mount "$ROOTPATH" /mnt
        mkdir /mnt/boot
        mount "$EFIPATH" /mnt/boot
        swapon "$SWAPPATH"
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
	fi
	exit
elif [ "$BOOTMODE" == "3" ]
then
	printf "Legacy BIOS has not been implemented yet.\n"
	exit
else										  
	printf '\e[31m%s\e[0m' "Error! Invalid answer\n"
	jumpto $start
fi





# Saving variables to config
printf "Variables you chose:\n" >> config
printf "+++++++++++++++++++++++++++++\n" >> config
printf "UEFI_ENABLED=$UEFI_ENABLED\n" >> config
printf "BOOTMODE=$BOOTMODE\n" >> config
printf "AUTOPART=$AUTOPART\n" >> config
printf "DISKTOAUTOPART=$DISKTOAUTOPART\n" >> config
printf "USESWAP=$USESWAP\n" >> config
printf "SWAPSIZE=$SWAPSIZE\n" >> config
printf "DISKTOPART=$DISKTOPART\n" >> config
printf "EFIPATH=$EFIPATH\n" >> config
printf "SWAPPATH=$SWAPPATH\n" >> config
printf "ROOTPATH=$ROOTPATH\n" >> config
printf "+++++++++++++++++++++++++++++\n" >> config


# Printing the variables
printf "Variables you chose:\n"
printf "+++++++++++++++++++++++++++++\n"
printf "UEFI_ENABLED=$UEFI_ENABLED\n"
printf "BOOTMODE=$BOOTMODE\n"
printf "AUTOPART=$AUTOPART\n"
printf "DISKTOAUTOPART=$DISKTOAUTOPART\n"
printf "USESWAP=$USESWAP\n"
printf "SWAPSIZE=$SWAPSIZE\n"
printf "DISKTOPART=$DISKTOPART\n"
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
