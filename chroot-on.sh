#!/bin/bash

dir=/mnt/custom

ROOT=/dev/sdb2
VAR=/dev/sdb3
HOME=/dev/sdb6

mount $ROOT $dir
mount --bind /sys $dir/sys
mount --bind /proc $dir/proc
mount --bind /dev $dir/dev
mount --bind /run $dir/run
mount $VAR $dir/var
mount $HOME $dir/home

chroot $dir
