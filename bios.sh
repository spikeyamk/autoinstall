#!/bin/bash

function biospart() {

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
            BIOSPATH="$DISKTOAUTOPART"
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
                    wipefs -a "$DISKTOAUTOPART"
                    (
                        echo o;
                        echo n;
                        echo ;
                        echo 1;
                        echo ;
                        echo +"$SWAPSIZE"G;
                        echo n;
                        echo ;
                        echo 2;
                        echo ;
                        echo ;
                        echo t;
                        echo 1;
                        echo 82;
                        echo a;
                        echo 2;
                        echo w;
                    ) | fdisk $DISKTOAUTOPART
                    SWAPPATH="$DISKTOAUTOPART""1"
                    ROOTPATH="$DISKTOAUTOPART""2"
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
                    wipefs -a "$DISKTOAUTOPART"
                    (
                        echo o;
                        echo n;
                        echo ;
                        echo 1;
                        echo ;
                        echo ;
                        echo a;
                        echo w;
                    ) | fdisk $DISKTOAUTOPART
                    ROOTPATH="$DISKTOAUTOPART""1"
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
            printf "Specify the path to the disk PATH: [e.g. /dev/sda]"
            read BIOSPATH
            printf "%s\n" "$BIOSPATH"

            # Disk partition table style test
            TEST=$(find "$EFIPATH" | fdisk -l | grep "Disklabel" | awk '{ print $(NF) }')
            if [ "$TEST" != "dos" ]
            then
                printf "\e[1;31mError! The disk uses an incorrect partition table style. Exiting the script!\e[0m"
                exit
            fi

            # BIOS Partition tests
            ###
            TEST=$(find "$BIOSPATH")
            if [ "$TEST" != "$BIOSPATH" ]
            then
                printf "\e[1;31mError! Specified BIOS disk does not exist\n\e[0m"
                jumpto $start
            fi
            ###
            # End of BIOS partition tests


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
                if [ "$TEST" != "Linux swap / Solaris" ]
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
                if [ "$TEST" != "Linux" ]
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
                if [ "$TEST" != "Linux" ]
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
    printf "\e[1;31mWARNING! Following partitions will be formatted: $SWAPPATH, $ROOTPATH\n\e[0m"
    printf "\e[1;31mAll data on them will be permanently erased. Do you wish to proceed? [y/n]: \e[0m"

    read ANSWER
    if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "n" ]
    then
        if [ "$ANSWER" == "y" ]
        then
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
    swapon "$SWAPPATH"

}
