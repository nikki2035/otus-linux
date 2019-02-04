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