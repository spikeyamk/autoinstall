#!/bin/bash

#cat locale.gen.tab.txt
rm UTFlocale.gen.tab
rm locale.gen.tab.index.txt


grep "UTF" locale.gen | cat | cut -c-3 > locale.gen.tab.txt

while read line;
do
	if [[ "$line" != "$previous" ]]
	then
		printf "$line\n" >> locale.gen.tab.index.txt
	fi
	previous="$line"
done < "locale.gen.tab.txt"
line="0"
sleep 2
i=0
while read test;
do
	#grep "$line" locale.gen > out.txt
	if [ $i -gt 0 ]
	then
		buffer="$(grep "$test" locale.gen)"
		printf "$buffer" >> fungujeto
		printf " \n" >> fungujeto
		printf " \n" >> fungujeto
	fi
	i=+1;
done < "locale.gen.tab.index.txt"
