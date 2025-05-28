#!/bin/bash

set -e

MASTER=192.168.0.64
MASTERPATH=/mnt/custom
NAME=$1
CLONE=/mnt/$NAME

if [ ! -d $CLONE ]; then
 mkdir $CLONE
fi

echo "Please enter the type of all system partitions (i.e. xfs, ext4 or other):"
FS_TYPE="ext4"

echo "Please enter the ROOT partition name (i.e. sda1 or other):"
ROOT_PART="sda1"

echo "Please enter the HOME partition name (i.e. sda2 or other):"
HOME_PART="sda2"

echo "Please enter the VAR partition name (i.e. sda5 or other, or the same as the ROOT one if included):"
VAR_PART="sda5"

echo "Please enter the SWAP partition name (i.e. sda6 or other):"
SWAP_PART="sda7"

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
echo "UUID=$uuid    /    $FS_TYPE    defaults,errors=remount-ro    0       1" >> $CLONE/etc/fstab
uuid=`get_uuid $HOME_PART`
echo "UUID=$uuid    /home    $FS_TYPE    defaults,errors=remount-ro    0       2" >> $CLONE/etc/fstab
if [ ! $VAR_PART == $ROOT_PART ]; then
 uuid=`get_uuid $VAR_PART`
 echo "UUID=$uuid    /var    $FS_TYPE    defaults,errors=remount-ro    0       2" >> $CLONE/etc/fstab
fi
uuid=`get_uuid $SWAP_PART`
echo "UUID=$uuid    none    swap    sw    0       0" >> $CLONE/etc/fstab


echo "Hello world, I'm an NEW TC clone ! :)"

