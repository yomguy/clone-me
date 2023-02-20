#!/bin/bash

set -e

OPTIND=1         # Reset in case getopts has been used previously in the shell.

ROOT="/"
FS_TYPE="ext4"

DISK=nvme0n1
EFI_PART="nvme0n1p1"
ROOT_PART="nvme0n1p2"
SWAP_PART="nvme0n1p3"

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
    mkfs.vfat /dev/$EFI_PART
    mkfs.$FS_TYPE -q /dev/$ROOT_PART
    mkswap /dev/$SWAP_PART
fi


mount /dev/$ROOT_PART $CLONE
mont  /dev/$EFI_PART $CLONE/boot/efi

if [ $SYNC ]; then
    # CLONING
    echo "rsyncing root..."
    rsync -a --delete --one-file-system $MASTER:$ROOT/ $CLONE/

    echo "rsyncing efi..."
    rsync -a --one-file-system --delete $MASTER:$ROOT/boot/efi $CLONE/boot/efi/
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
uuid=`get_uuid $EFI_PART`
echo "UUID=$uuid    /bot/efi    vfat    umask=0077    0       1" >> $CLONE/etc/fstab
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
umount $CLONE/boot/efi
umount $CLONE

echo "Hello world, I'm $ID cloned from $MASTER ! :)"
