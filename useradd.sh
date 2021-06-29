#!/bin/bash

printf "Choose a username: ";

read username

useradd -m "$username"

passwd "$username"

usermod -aG wheel,video,optical,storage "$username"
