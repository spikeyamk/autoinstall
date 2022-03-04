#!/bin/bash

printf "Now selected the desired locales. We recommend to select at least one locale in UTF-8 enconding.\n"
printf "[If left blank en_US.UTF-8 is selected by default]\n"
sleep 2

grep "UTF" locale.gen | cat -b
grep "UTF" locale.gen | cat | cut -c-3 > locale.gen.tab.txt

#grep "ISO" locale.gen | cat -b

#while read line;
#do
#	for word in $line;
#	do
#		#printf "$word"
#		#sleep 2
#		if [[ "$word" =~ ^[[:upper:]]+$ ]]
#		then
#		#	printf "HELLO\n"
#			printf "$word\n"
#		fi
#	done
#done < "table.txt"




bash sort.sh >> outputik
