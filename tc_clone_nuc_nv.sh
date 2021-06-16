#!/bin/bash

set -e

OPTIND=1         # Reset in case getopts has been used previously in the shell.

ROOT="/"
FS_TYPE="ext4"

DISK=nvme0n1
ROOT_PART="nvme0n1p1"
VAR_PART="nvme0n1p2"
SWAP_PART="nvme0n1p3"
HOME_PART="nvme0n1p4"

while getopts m:i:p:r:s:d:f flag
do
    case "${flag}" in
        m) MASTER=${OPTARG};;
        i) ID=${OPTARG};;
        f) FORMAT=true;;
        r) ROOT=${OPTARG};;
        s) SYNC=true;;
        p) PARTITIONS=${OPTARG};;
    esac
done

CLONE=/mnt/$ID
if [ ! -d $CLONE ]; then
 mkdir $CLONE
fi

#umount /dev/$HOME_PART $$CLONE/home
#umount /dev/$VAR_PART $CLONE/var
#umount /dev/$ROOT_PART $CLONE

if [ $PARTITIONS ]; then
    sfdisk /dev/$DISK < $PARTITIONS
fi

if [ $FORMAT ]; then
    mkfs.$FS_TYPE -q /dev/$ROOT_PART
    mkfs.$FS_TYPE -q /dev/$VAR_PART
    mkfs.$FS_TYPE -q  /dev/$HOME_PART
    mkswap /dev/$SWAP_PART
fi


mount /dev/$ROOT_PART $CLONE

DEST=$CLONE/var
if [ ! -d $DEST ]; then
  mkdir $DEST
fi
mount /dev/$VAR_PART $CLONE/var

DEST=$CLONE/home
if [ ! -d $DEST ]; then
   mkdir $DEST
fi
mount /dev/$HOME_PART $CLONE/home

if [ $SYNC ]; then
    # CLONING
    echo "rsyncing root..."
    rsync -a --delete --exclude "/var/*" --exclude "/home/*" --one-file-system $MASTER:$ROOT/ $CLONE/

    echo "rsyncing var..."
    rsync -a --one-file-system --delete $MASTER:$ROOT/var/ $CLONE/var/

    echo "rsyncing home..."
    rsync -a --one-file-system --exclude "archives/*" --exclude "trash/*" --exclude "test/*" --exclude "edit/*" $MASTER:$ROOT/home/ $CLONE/home/
fi

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

echo "RESUME=UUID=$uuid" >> $CLONE/etc/initramfs-tools/conf.d/resume

echo $ID > $CLONE/etc/hostname

# CHROOT
mount --bind /sys $CLONE/sys
mount --bind /proc $CLONE/proc
mount --bind /dev $CLONE/dev
mount --bind /dev/pts $CLONE/dev/pts

# GRUB
chroot $CLONE grub-install /dev/nvme0n1
chroot $CLONE update-initramfs -u
chroot $CLONE update-grub

# UMOUNT
umount $CLONE/dev/pts
umount $CLONE/dev
umount $CLONE/proc
umount $CLONE/sys
umount $CLONE/var
umount $CLONE/home
umount $CLONE

echo "Hello world, I'm $ID cloned from $MASTER ! :)"
