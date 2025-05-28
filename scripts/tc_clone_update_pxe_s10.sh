#!/bin/bash

set -e

MASTER=192.168.0.62
MASTERPATH=/mnt/custom
NAME=$1
CLONE=/mnt/$NAME

if [ ! -d $CLONE ]; then
 mkdir $CLONE
fi

mount /dev/sda1 $CLONE
echo "rsyncing root..."
rsync -a --delete --one-file-system --exclude=/etc/fstab --exclude=/etc/hostname --exclude=/etc/hosts $MASTER:$MASTERPATH/ $CLONE/

echo "rsyncing home..."
mount /dev/sda3 $CLONE/home
rsync -a --exclude=telecaster/archives --exclude=telecaster/trash --exclude=telecaster/bin --exclude=telecaster/test $MASTER:$MASTERPATH/home/ $CLONE/home/
umount $CLONE/home

echo "rsyncing var..."
rsync -a --delete $MASTER:$MASTERPATH/var/ $CLONE/var/

# CHROOT
mount -t proc none $CLONE/proc
mount -o bind /dev $CLONE/dev
mount -o bind /sys $CLONE/sys

chroot $CLONE grub-install /dev/sda
chroot $CLONE update-grub

umount $CLONE/sys
umount $CLONE/dev
umount $CLONE/proc

#umount $CLONE/var
umount $CLONE

echo "OK, I'm an updated TC (s10) clone!"


