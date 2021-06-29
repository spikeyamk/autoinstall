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
genfstab -U /mnt >> /mnt/etc/fstab
