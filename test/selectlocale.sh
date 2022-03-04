#!/bin/bash

printf "Now selected the desired locales. We recommend to select at least one locale in UTF-8 enconding\n"
printf "[If left blank en_US.UTF-8 is selected by default]\n"

cat locale.gen | grep UTF-8
