
rsync -a --one-file-system --exclude=/boot --exclude=/et/fstab --exclude=/etc/cryptsetup-initramfs/ --exclude=/etc/crypttab --exclude=/etc/initramfs-tools $1/ $2/
