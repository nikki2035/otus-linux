#Создать рейд
#
#получить список дисков
sudo lshw -short | grep disk
#занулить суперблоки
sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
#создать пятый рейд из пяти устройств
sudo mdadm --create --verbose /dev/md0 -l 5 -n 5 /dev/sd{b,c,d,e,f}
#получить информацию о рейде
sudo mdadm -D /dev/md0
#информация о конфигурации
sudo mdadm --detail --scan --verbose
#создать директорию для конфига
sudo mkdir /etc/mdadm
#создать файл конфигурации
sudo echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
sudo mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >>/etc/mdadm/mdadm.conf
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