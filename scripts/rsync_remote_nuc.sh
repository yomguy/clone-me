
mount /dev/sdg2 /mnt/custom
mount /dev/sdg3 /mnt/custom/var
mount /dev/sdg6 /mnt/custom/home

sudo rsync -a --one-file-system -e 'ssh -p 22022' root@localhost:/ /mnt/custom/ 
sudo rsync -a --one-file-system -e 'ssh -p 22022' root@localhost:/var/ /mnt/custom/var/
sudo rsync -a --one-file-system --exclude=archives --exclude=trash  -e 'ssh -p 22022' root@localhost:/home/ /mnt/custom/home/

