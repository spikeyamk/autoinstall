#!/bin/bash

fdisk /dev/sda << FDISK_CMDS
g
n
1
 
+64MiB
n
2
 
 
t
1
83
t
2
83
w
FDISK_CMDS
