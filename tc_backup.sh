#!/bin/bash

set -e

echo "Please enter the MASTER_HOST address:"
read MASTER_HOST

echo "Please enter the MASTER_PATH:"
read MASTER_PATH

echo "Please enter the BACKUP_PATH:"
read BACKUP_PATH

CLONE=$BACKUP_PATH

if [ ! -d $CLONE ]; then
 mkdir $CLONE
fi

# CLONING
echo "rsyncing root..."
rsync -a --delete --exclude "/var/*" --exclude "/home/*" --one-file-system $MASTER_HOST:$MASTER_PATH/ $CLONE/

echo "rsyncing var..."
DEST=$CLONE/var
if [ ! -d $DEST ]; then
 mkdir $DEST
fi
rsync -a --one-file-system --delete $MASTER_HOST:$MASTER_PATH/var/ $CLONE/var/

echo "rsyncing home..."
DEST=$CLONE/home
if [ ! -d $DEST ]; then
 mkdir $DEST
fi
rsync -a --one-file-system --exclude "archives/*" --exclude "trash/*" --exclude "test/*" $MASTER_HOST:$MASTER_PATH/home/ $CLONE/home/

echo "$MASTER_HOST has been backup to $BACKUP_PATH ! :)"
