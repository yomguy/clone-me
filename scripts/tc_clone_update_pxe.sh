#!/bin/bash

set -e

MASTER=192.168.0.64
MASTERPATH=/mnt/custom
NAME=$1
CLONE=/mnt/$NAME

if [ ! -d $CLONE ]; then
 mkdir $CLONE
fi

# CLONING
mount /dev/sda1 $CLONE
echo "rsyncing root..."
rsync -a --delete --one-file-system --exclude=/etc/fstab --exclude=/etc/hostname --exclude=/etc/hosts $MASTER:$MASTERPATH/ $CLONE/

echo "rsyncing home..."
mount /dev/sda2 $CLONE/home
rsync -a --delete --exclude=telecaster/archives --exclude=telecaster/trash --exclude=telecaster/bin --exclude=home/telecaster/test --exclude=networkmanagement $MASTER:$MASTERPATH/home/ $CLONE/home/
umount $CLONE/home

echo "rsyncing var..."
mount /dev/sda5 $CLONE/var
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

umount $CLONE/var
umount $CLONE

echo "OK, I'm an updated TC clone!"

