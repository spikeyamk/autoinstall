#!/bin/bash

function uefipart() {
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
                # Linux root filesystem parition size test
                TEST=$(lsblk -b "$ROOTPATH" | awk '{print $4}' | awk 'NR==2')
                if [[ $((TEST)) -lt 4294967296 ]]
                then
                    printf "\e[1;31mError! The Linux root filesystem partition is too small. Its size has to be at least 300 MiB.\n\e[0m"
                    exit
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
                # Linux root filesystem parition size test
                TEST=$(lsblk -b "$ROOTPATH" | awk '{print $4}' | awk 'NR==2')
                if [[ $((TEST)) -lt 4294967296 ]]
                then
                    printf "\e[1;31mError! The Linux root filesystem partition is too small. Its size has to be at least 300 MiB.\n\e[0m"
                    exit
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

}
