#!/bin/bash

set -e

CLONE=/mnt/custom

mount /dev/sda1 $CLONE
mount /dev/sda2 $CLONE/home
mount /dev/sda5 $CLONE/var

df

echo "OK, I'm the Master of the TC clones!"

