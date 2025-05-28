#!/bin/bash

set -e

CLONE=/mnt/custom

mount /dev/sda1 $CLONE
mount /dev/sda2 $CLONE/var
mount /dev/sda4 $CLONE/home

df

echo "OK, I'm the Master of the TC clones!"
