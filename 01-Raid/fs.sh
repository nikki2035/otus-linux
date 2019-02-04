
#пометить диск поврежденным
sudo mdadm /dev/md0 --fail /dev/sde
#посмотреть, как отразилось на рейде
cat /proc/mdstat
sudo mdadm -D /dev/md0
#удалить диск из рейда
sudo mdadm /dev/md0 --remove /dev/sde
#добавить новый
sudo mdadm /dev/md0 --add /dev/sde
#проверить
mdadm -D /dev/md0
#
#создать GPT раздел
sudo parted -s /dev/md0 mklabel gpt
#создать партиции
sudo parted /dev/md0 mkpart primary ext4 0% 20%
sudo parted /dev/md0 mkpart primary ext4 20% 40%
sudo parted /dev/md0 mkpart primary ext4 40% 60%
sudo parted /dev/md0 mkpart primary ext4 60% 80%
sudo parted /dev/md0 mkpart primary ext4 80% 100%
#создать файловую систему на партициях
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
#создать точки монтирования
sudo mkdir -p /raid/part{1,2,3,4,5}
#примонтировать
for i in $(seq 1 5); do sudo mount /dev/md0p$i /raid/part$i; done