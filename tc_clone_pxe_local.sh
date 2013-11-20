#!/bin/bash

set -e

MASTERPATH=/mnt/custom
NAME=$1
CLONE=/mnt/$NAME

FS_TYPE="ext4"

ROOT_PART="sdb1"
HOME_PART="sdb2"
VAR_PART="sdb5"
SWAP_PART="sdb6"


if [ ! -d $CLONE ]; then
 mkdir $CLONE
fi

mount /dev/$ROOT_PART $CLONE
echo "rsyncing root..."
rsync -a --delete --one-file-system $MASTERPATH/ $CLONE/

echo "rsyncing home..."
mount /dev/$HOME_PART $CLONE/home
rsync -a --delete --one-file-system --exclude=telecaster/archives/ --exclude=telecaster/trash/ --exclude=telecaster/test/ $MASTERPATH/home/ $CLONE/home/
umount $CLONE/home

echo "rsyncing var..."
mount /dev/$VAR_PART $CLONE/var
rsync -a --delete --one-file-system $MASTERPATH/var/ $CLONE/var/


# CHROOT
mount -t proc none $CLONE/proc
mount -o bind /dev $CLONE/dev
mount -o bind /sys $CLONE/sys

get_uuid () {
disks=/dev/disk/by-uuid
for id in `ls $disks`; do
 part=`readlink -f $disks/$id`
 if [ $part == /dev/$1 ]; then
  echo $id
 fi
done
}

uuid=`get_uuid $ROOT_PART`
echo "UUID=$uuid    /    $FS_TYPE    defaults,errors=remount-ro    0       1" > $CLONE/etc/fstab
uuid=`get_uuid $HOME_PART`
echo "UUID=$uuid    /home    $FS_TYPE    defaults,errors=remount-ro    0       2" >> $CLONE/etc/fstab
uuid=`get_uuid $VAR_PART`
echo "UUID=$uuid    /var    $FS_TYPE    defaults,errors=remount-ro    0       2" >> $CLONE/etc/fstab
uuid=`get_uuid $SWAP_PART`
echo "UUID=$uuid    none    swap    sw    0       0" >> $CLONE/etc/fstab

echo $NAME > $CLONE/etc/hostname

chroot $CLONE grub-install /dev/sdb
chroot $CLONE update-grub

umount $CLONE/sys
umount $CLONE/dev
umount $CLONE/proc

umount $CLONE/var
umount $CLONE/

echo "Hello world, I'm a NEW TC-202 clone ! B-)"


