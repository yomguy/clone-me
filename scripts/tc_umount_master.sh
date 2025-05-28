#!/bin/bash

set -e

CLONE=/mnt/custom

umount $CLONE/var
umount $CLONE/home
umount $CLONE

df


