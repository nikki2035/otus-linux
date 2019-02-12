# Работа с LVM
Вывод в lvm.txt

# Домашняя работа
## Запись работы и подключение к виртуалке
script -aq
vagrant ssh
sudo su
yum -y install xfsdump

# Работа с файловой системой
## Уменьшить том под / до 8G
### Создать новый раздел и переместить туда /
lsblk
pvcreate /dev/sdb
vgcreate vg_root /dev/sdb
lvcreate -n lv_root -l +100%FREE /dev/vg_root
mkfs.xfs /dev/vg_root/lv_root
mount /dev/vg_root/lv_root /mnt
lvmdiskscan
xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done
в файле /boot/grub2/grub.cfg
заменитþ rd.lvm.lv=VolGroup00/LogVol00 на rd.lvm.lv=vg_root/lv_root
exit
reboot
### Пересоздать раздел и переместить / обратно
vagrant ssh
sudo su
lsblk
lvmdiskscan
lvremove /dev/VolGroup00/LogVol00
lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
mkfs.xfs /dev/VolGroup00/LogVol00
mount /dev/VolGroup00/LogVol00 /mnt
xfsdump -J - /dev/vg_root/lv_root | xfsrestore -J - /mnt
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done

## выделить том под /var
pvcreate /dev/sdc /dev/sdd
vgcreate vg_var /dev/sdc /dev/sdd

## /var - сделать в mirror
lvcreate -L 950M -m1 -n lv_var vg_var
mkfs.ext4 /dev/vg_var/lv_var
mount /dev/vg_var/lv_var /mnt
cp -aR /var/* /mnt/ 
mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
umount /mnt
mount /dev/vg_var/lv_var /var
echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
exit
reboot

## выделить том под /home
sudo su
lvremove /dev/vg_root/lv_root
vgremove /dev/vg_root
pvremove /dev/sdb
lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
mkfs.xfs /dev/VolGroup00/LogVol_Home
mount /dev/VolGroup00/LogVol_Home /mnt/
cp -aR /home/* /mnt/ 
rm -rf /home/*
umount /mnt
mount /dev/VolGroup00/LogVol_Home /home/

## прописать монтирование в fstab
echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab

### cгенерить файлы в /home/
touch /home/file{1..20}

## /home - сделать том для снэпшотов
lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home

### снять снэпшот

### удалить часть файлов
rm -f /home/file{11..20}

### восстановится со снэпшота
И вот тут та же самая проблема - не работает
umount /home

umount: /home: target is busy.
        (In some cases useful info about processes that use
         the device is found by lsof(8) or fuser(1))

lvconvert --merge /dev/VolGroup00/home_snap
mount /home