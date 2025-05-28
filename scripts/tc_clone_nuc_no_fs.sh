#!/bin/bash

set -e

echo "Please enter the MASTER_HOST address:"
read MASTER_HOST

echo "Please enter the MASTER_HOST path:"
read MASTER_PATH

echo "Please enter the target system ID:"
read ID

FS_TYPE="ext4"

UEFI_PART="sda1"
ROOT_PART="sda2"
VAR_PART="sda3"
SWAP_PART="sda5"
HOME_PART="sda6"

#mkfs.vfat /dev/$UEFI_PART
#mkfs.$FS_TYPE /dev/$ROOT_PART
#mkfs.$FS_TYPE /dev/$VAR_PART
#mkfs.$FS_TYPE /dev/$HOME_PART
#mkswap /dev/$SWAP_PART

CLONE=/mnt/$ID
if [ ! -d $CLONE ]; then
 mkdir $CLONE
fi

# CLONING
mount /dev/$ROOT_PART $CLONE
echo "rsyncing root..."
rsync -a --delete --exclude "/var/*" --exclude "/home/*" --one-file-system $MASTER_HOST:$MASTER_PATH/ $CLONE/

echo "rsyncing var..."
DEST=$CLONE/var
if [ ! -d $DEST ]; then
 mkdir $DEST
fi
if [ ! $VAR_PART == $ROOT_PART ]; then
 mount /dev/$VAR_PART $CLONE/var
fi
rsync -a --one-file-system --delete $MASTER_HOST:$MASTER_PATH/var/ $CLONE/var/

echo "rsyncing home..."
DEST=$CLONE/home
if [ ! -d $DEST ]; then
 mkdir $DEST
fi
mount /dev/$HOME_PART $DEST
rsync -a --one-file-system --exclude "archives/*" --exclude "trash/*" --exclude "test/*" $MASTER_HOST:$MASTER_PATH/home/ $CLONE/home/
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

echo $ID > $CLONE/etc/hostname

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

echo "Hello world, I'm $ID cloned from $MASTER_HOST ! :)"
