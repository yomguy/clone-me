#!/bin/bash

dir=/mnt/custom

ROOT=/dev/sdg2
VAR=/dev/sdg3
HOME=/dev/sdg6

mount $ROOT $dir
mount --bind /sys $dir/sys
mount --bind /proc $dir/proc
mount --bind /dev $dir/dev
mount --bind /dev/pts $dir/dev/pts
#mount --bind /run $dir/run
mount $VAR $dir/var
mount $HOME $dir/home

chroot $dir
