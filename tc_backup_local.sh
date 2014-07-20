#!/bin/bash

set -e

echo "Please enter the MASTER_PATH:"
read MASTER_PATH

echo "Please enter the BACKUP_PATH:"
read BACKUP_PATH

CLONE=$BACKUP_PATH

if [ ! -d $CLONE ]; then
 sudo mkdir $CLONE
fi

# CLONING
echo "rsyncing root..."
sudo rsync -a --delete --exclude "/var/*" --exclude "/home/*" --one-file-system $MASTER_PATH/ $CLONE/

echo "rsyncing var..."
DEST=$CLONE/var
if [ ! -d $DEST ]; then
 sudo mkdir $DEST
fi
sudo rsync -a --one-file-system --delete $MASTER_PATH/var/ $CLONE/var/

echo "rsyncing home..."
DEST=$CLONE/home
if [ ! -d $DEST ]; then
 sudo mkdir $DEST
fi
sudo rsync -a --one-file-system --exclude "archives/*" --exclude "trash/*" --exclude "test/*" $MASTER_PATH/home/ $CLONE/home/

echo "$MASTER_PATH has been backup to $BACKUP_PATH ! :)"
