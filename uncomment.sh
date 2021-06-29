#!/bin/bash

sed -i '/en_US.UTF-8/s/^#//g' /etc/locale.gen
