#!/bin/bash

TEST=$(grep -i vendor_id /proc/cpuinfo | sed '1,2d' | awk '{print $NF }');

printf "%s\n" "$TEST";

if [ "$TEST" = "GenuineIntel" ];
	sudo pacman -S intel-ucode;
else 
	sudo pacman -S amd-ucode;
fi
