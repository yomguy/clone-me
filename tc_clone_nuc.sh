#!/bin/bash

set -e

echo "Please enter the IP address of the master:"
read MASTER

echo "Please enter the target system name:"
read NAME

MASTERPATH=/mnt/custom
FS_TYPE="ext4"

ROOT_PART="sda1"
VAR_PART="sda2"
SWAP_PART="sda3"
HOME_PART="sda4"

CLONE=/mnt/$NAME
if [ ! -d $CLONE ]; then
 mkdir $CLONE
fi

# CLONING
mount /dev/$ROOT_PART $CLONE
echo "rsyncing root..."
rsync -a --delete --one-file-system $MASTER:$MASTERPATH/ $CLONE/

echo "rsyncing var..."
DEST=$CLONE/var
if [ ! -d $DEST ]; then
 mkdir $DEST
fi
if [ ! $VAR_PART == $ROOT_PART ]; then
 mount /dev/$VAR_PART $CLONE/var
fi
rsync -a --one-file-system --delete $MASTER:$MASTERPATH/var/ $CLONE/var/

echo "rsyncing home..."
DEST=$CLONE/home
if [ ! -d $DEST ]; then
 mkdir $DEST
fi
mount /dev/$HOME_PART $DEST
rsync -a --one-file-system --exclude=$MASTER:/home/telecaster/archives/ --exclude=$MASTER:/home/telecaster/trash/ \
     --exclude=$MASTER:/home/telecaster/test/ $MASTER:$MASTERPATH/home/ $CLONE/home/
umount $CLONE/home

# FSTAB
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
if [ ! $VAR_PART == $ROOT_PART ]; then
 uuid=`get_uuid $VAR_PART`
 echo "UUID=$uuid    /var    $FS_TYPE    defaults,errors=remount-ro    0       2" >> $CLONE/etc/fstab
fi
uuid=`get_uuid $HOME_PART`
echo "UUID=$uuid    /home    $FS_TYPE    defaults,errors=remount-ro    0       2" >> $CLONE/etc/fstab
uuid=`get_uuid $SWAP_PART`
echo "UUID=$uuid    none    swap    sw    0       0" >> $CLONE/etc/fstab

echo $NAME > $CLONE/etc/hostname

# CHROOT
mount -t proc none $CLONE/proc
mount -o bind /dev $CLONE/dev
mount -o bind /sys $CLONE/sys

# GRUB
chroot $CLONE grub-install /dev/sda
chroot $CLONE update-grub

# UMOUNT
umount $CLONE/sys
umount $CLONE/dev
umount $CLONE/proc

umount $CLONE/var
umount $CLONE

echo "Hello world, I'm an NEW TC clone ! :)"
