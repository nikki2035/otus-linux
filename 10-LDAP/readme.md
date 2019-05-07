
# LDAP

Vagrantfile создаёт две машины, сервер и клиент и запускает соответствующие плейбуки.

## Установить FreeIPA

Для установки FreeIPA сервера необходимо минимум 2гб оперативной памяти, иначе конфигурирование идёт с ошибками.

Для установки необходимо прописать FQDN в хостнейм.

```
hostnamectl set-hostname freeipa-server.otus.local
```

По причине отсутствия DNS пропишем в hosts машины. Сам сервер на сервере прописывать нельзя - тогда не устанавливается.

```
echo "192.168.11.102 freeipa-client.otus.local freeipa-client" >> /etc/hosts
```

Настроим время для работы Kerberos

```
ntpdate 1.ru.pool.ntp.org
mv /etc/localtime /etc/localtime.bak
ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime
```

## Написать playbook для конфигурации клиента

Установка и конфигурирование и сервера, и клиента осуществляется с помощью ansible playbook
