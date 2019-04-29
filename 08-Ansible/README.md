Подготовить стенд на Vagrant как минимум с одним сервером. На этом сервере используя Ansible необходимо развернуть nginx со следующими условиями:
- необходимо использовать модуль yum/apt
- конфигурационные файлы должны быть взяты из шаблона jinja2 с переменными
- после установки nginx должен быть в режиме enabled в systemd
- должен быть использован notify для старта nginx после установки
- сайт должен слушать на нестандартном порту - 8080, для этого использовать переменные в Ansible

# Выполнение

```
vagrant up
ansible-playbook playbooks/nginx.yml
curl http://192.168.11.151:8080
```

* Сделать все это с использованием Ansible роли

# Описание

## Установка Ansible

Версия Ansible =>2.4 требует для своей работы Python 2.6 или выше

```
python -V
Python 2.7.15
```

Далее произведите установку для Вашей ОС и убедитесь что Ansible установлен корректно:

```
yum -y install ansible
ansible --version
ansible 2.7.10
```

## Настройка Ansible

Для управления хостами Ansible использует SSH соединение. Поэтому перед стартом необходимо убедиться что у Вас есть доступ до управляемых хостов.

Также на управляемых хостах должен быть установлен Python 2.X

### Подготовка окружения

Для подключения к хосту nginx нам необходимо будет передать множество
параметров - это особенность Vagrant. Узнать эти параметры можно с
помощью команды vagrant ssh-config. Вот основные необходимые нам:

```
vagrant ssh-config
Host host1 - имя хоста
  HostName 127.0.0.1 - IP адрес
  User vagrant - имя пользователя под которым подключаемся
  Port 2200 - порт, который проброшен на 127.0.0.1
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile /home/nikki/Документы/otus-linux/08-Ansible/.vagrant/machines/host1/virtualbox/private_key - путь до приватного ключа
  IdentitiesOnly yes
  LogLevel FATAL

Host host2 - имя хоста
  HostName 127.0.0.1 - IP адрес
  User vagrant - имя пользователя под которым подключаемся
  Port 2201 - порт, который проброшен на 127.0.0.1
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile /home/nikki/Документы/otus-linux/08-Ansible/.vagrant/machines/host2/virtualbox/private_key - путь до приватного ключа
  IdentitiesOnly yes
  LogLevel FATAL
```

Используя эти параметры создадим inventory файл:

```
[webservers]
host1 ansible_host=127.0.0.1 ansible_port=2200 ansible_user=vagrant ansible_private_key_file=.vagrant/machines/host1/virtualbox/private_key
host2 ansible_host=127.0.0.1 ansible_port=2201 ansible_user=vagrant ansible_private_key_file=.vagrant/machines/host2/virtualbox/private_key
```

Убедимся, что Ansible может управлять нашим хостом:

```
ansible host1 -i staging/hosts -m ping
host1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Создадим файл ansible.cfg со следующим содержанием:

```
[defaults]
inventory = staging/hosts
remote_user= vagrant
host_key_checking = False
```

Теперь из инвентори можно убрать информацию о пользователе.

Еще раз убедимся, что управляемый хост доступе, только теперь без явного указания inventory файла:

```
ansible host1 -i staging/hosts -m ping
host1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### Ad-Hoc команды

Посмотрим какое ядро установлено на хосте

```
ansible host1 -m command -a "uname -r"
host1 | CHANGED | rc=0 >>
3.10.0-957.1.3.el7.x86_64
```

Проверим статус сервиса firewalld

```
ansible host1 -m systemd -a name=firewalld
host1 | SUCCESS => {
    "changed": false,
    "name": "firewalld",
    "status": {
        "ActiveEnterTimestampMonotonic": "0",
        "ActiveExitTimestampMonotonic": "0",
        "ActiveState": "inactive",
```

Установим пакет epel-release на наш хост

```
nsible host1 -m yum -a "name=epel-release state=present" -b
host1 | CHANGED => {
    "ansible_facts": {
        "pkg_mgr": "yum"
    },
    "changed": true,
```

### Playbook

Создадим playbooks/epel.yml со следуящим содержимым:

```
- name: Install EPEL Repo
  hosts: host2
  become: true
  tasks:
   - name: Install EPEL Repo package from standard repo
     yum:
      name: epel-release
      state: present
```

После чего запустите выполнение Playbook

```
ansible-playbook playbooks/epel.yml

PLAY [Install EPEL Repo] *******************************************************

TASK [Gathering Facts] *********************************************************
ok: [host2]

TASK [Install EPEL Repo package from standard repo] ****************************
changed: [host2]

PLAY RECAP *********************************************************************
host2                      : ok=2    changed=1    unreachable=0    failed=0
```

Теперь собственно приступим к выполнению домашнего задания и написанию Playbook-а для установки NGINX. Будем писать его постепенно, шаг за шагом. И в итоге трансформируем его в роль.

За основу возьмем уже созданный нами файл epel.yml, создадим playbooks/nginx.yml. И первым делом добавим в него установку пакета NGINX.

```
   - name: Install nginx package from epel repo
     yum:
      name: nginx
      state: latest
     tags:
      - nginx-package
      - packages
```

Обратите внимание - добавили Tags. Теперь можно вывести в консоль список тегов и выполнить, например, только установку NGINX. В нашем случае так, например, можно осуществлять его обновление.

Выведем в консоль все теги:

```
ansible-playbook nginx.yml --list-tags

playbook: nginx.yml

  play #1 (host2): Install EPEL Repo	TAGS: []
      TASK TAGS: [nginx-package, packages]
```

Запустим только установку NGINX

```
ansible-playbook nginx.yml -t nginx-package

PLAY [Install and configure NGINX] *******************************************************************************************************

TASK [Gathering Facts] *********************************************************************************************************
ok: [host2]

TASK [Install nginx package from epel repo] ************************************************************************************
changed: [host2]

PLAY RECAP *********************************************************************************************************************
host2                      : ok=2    changed=1    unreachable=0    failed=0   
```

Далее добавим шаблон для конфига NGINX и модуль, который будет копировать этот шаблон на хост:

```
- name: Create NGINX config file from template
 template:
 src: templates/nginx.conf.j2
 dest: /tmp/nginx.conf
 tags:
 - nginx-configuration
```

Сразу же пропишем в Playbook необходимуя нам переменнуя. Нам нужно чтобы NGINX слушал на порту 8080:

```
- name: Install and configure NGINX
 hosts: nginx
 become: true
 vars:
 nginx_listen_port: 8080
```

Сам шаблон будет выглядеть так:

```
# {{ ansible_managed }}
events {
    worker_connections 1024;
}

http {
    server {
        listen       {{ nginx_listen_port }} default_server;
        server_name  default_server;
        root         /usr/share/nginx/html;

        location / {
        }
    }
}
```

Теперь создадим handler и добавим notify к копированию шаблона. Теперь каждый раз когда конфиг будет изменяться - сервис перезагрузится. Так же создадим handler для рестарта и включения сервиса при загрузке.

Секция с handlers будет выглядеть следуящим образом:

```
handlers:
 - name: restart nginx
 systemd:
 name: nginx
 state: restarted
 enabled: yes

 - name: reload nginx
 systemd:
 name: nginx
 state: reloaded
```

Notify будут выглядеть так:

```
- name: Install nginx package from epel repo
     yum:
      name: nginx
      state: latest
     notify:
      - restart nginx
     tags:
      - nginx-package
      - packages

   - name: Create NGINX config file from template
     template:
       src: templates/nginx.conf.j2
       dest: /tmp/nginx.conf
     notify:
     - reload nginx
     tags:
     - nginx-configuration
```

Теперь можно запустить его в Ansible

```
ansible-playbook playbooks/nginx.yml

PLAY [Install and configure NGINX] *********************************************************************************************

TASK [Gathering Facts] *********************************************************************************************************
ok: [host2]

TASK [Install EPEL Repo package from standard repo] ****************************************************************************
ok: [host2]

TASK [Install nginx package from epel repo] ************************************************************************************
ok: [host2]

TASK [Create NGINX config file from template] **********************************************************************************
changed: [host2]

RUNNING HANDLER [reload nginx] *************************************************************************************************
changed: [host2]

PLAY RECAP *********************************************************************************************************************
host2                      : ok=6    changed=2    unreachable=0    failed=0   
```

Теперь можно перейти в браузере по адресу http://192.168.11.150:8080 и убедиться, что сайт доступен.

Или из консоли выполнить команду:

```
curl http://192.168.11.151:8080
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
    <head>
        <title>Test Page for the Nginx HTTP Server on Fedora</title>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <style type="text/css">
            /*<![CDATA[*/
            body {
```
