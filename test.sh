#!/bin/bash

fdisk /dev/sda << FDISK_CMDS
g
n
1
 
+300M
n
2
 
+1G
n
3


t
1
1
t
2
19
w
FDISK_CMDS
