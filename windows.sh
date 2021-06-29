#!/bin/bash

function jumpto
{
	label=$1
	cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$') 
	eval "$cmd"
	exit
}

start=${1:-"start"}

start:
printf "Do you wish to integrate a win parition inside GRUB.conf [y/n]? ;";
read answer;

if [ "$answer" == "y" ] || [ "$answer" == "n" ]
then
	printf "%s\n" "$answer";
	if [ "$answer" == "y" ]
	then 
		printf "Specify the [WIN partition] path: ";
		read WINPATH
		mkdir /mnt/win;
		mount "$WINPATH" /mnt/win;
	fi
else
	printf "Error! Unvalid character\n";
	jumpto $start

fi
