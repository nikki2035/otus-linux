# Написать сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig

## Все скрипты добавлены в vagrantfile

Для начала создаём файл с конфигурацией для сервиса в директории /etc/sysconfig - из неё сервис будет брать необходимые переменные.

```
vi /etc/sysconfig/watchlog
# Configuration file for my watchdog service
# Place it to /etc/sysconfig
# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log
```

Затем создаем ``/var/log/watchlog.log`` и пишем туда строки на своё усмотрение, плюс ключевое слово ``ALERT``

Создадим скрипт:

```
vi /opt/watchlog.sh
#!/bin/bash
WORD=$1
LOG=$2
DATE=`date`
if [ "grep $WORD $LOG &> /dev/null" ];
then
logger "$DATE: I found word, Master!"
else
exit 0
fi
```

Команда ``logger`` отправляет лог в системный журнал\
Создадим юнит для сервиса:

```
vi /etc/systemd/system/watchlog.service
[Unit]
Description=My watchlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchdog
ExecStart=/opt/watchlog.sh $WORD $LOG
```

Создадим юнит для таймера:

```
[Unit]
Description=Run watchlog script every 30 second

[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service

[Install]
WantedBy=multi-user.target
```

Затем достаточно только стартануть timer:

```
systemctl start watchlog.timer
```

И убедиться в результате:

```
tail -f /var/log/messages
Mar 19 14:24:32 firepc2 systemd: Started Run watchlog script every 30 second.
Mar 19 14:24:32 firepc2 systemd: Starting Run watchlog script every 30 second.
Mar 19 14:25:33 firepc2 systemd: Starting My watchlog service...
Mar 19 14:25:33 firepc2 root: Tue Mar 19 14:25:33 UTC 2019: I found word, Master!
Mar 19 14:25:33 firepc2 systemd: Started My watchlog service.
Mar 19 14:26:37 firepc2 systemd: Starting My watchlog service...
Mar 19 14:26:37 firepc2 root: Tue Mar 19 14:26:37 UTC 2019: I found word, Master!
```

# Из epel установить spawn-fcgi и переписать init-скрипт на unit-файл. Имя сервиса должно также называться.
Устанавливаем spawn-fcgi и необходимые для него пакеты:

```
yum install -y epel-release && yum install -y spawn-fcgi php php-cli mod_fcgid httpd
```

``etc/rc.d/init.d/spawn-fcg`` - cам init скрипт, который будем переписывать, но перед этим необходимо раскомментировать строки с переменными в ``/etc/sysconfig/spawn-fcgi``\
Он должен получится следующего вида:

```
vi /etc/sysconfig/spawn-fcgi
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi"
```

А сам юнит файл будет следующего вида:

```
touch /etc/systemd/system/spawn-fcgi.service
vi /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
```

Убеждаемся, что все успешно работает:

```
systemctl start spawn-fcgi
systemctl status spawn-fcgi
```

# Дополнить юнит-файл apache httpd возможностью запустить несколько инстансов сервера с разными конфигами

Для запуска нескольких экземпляров сервиса будем использовать шаблон в
конфигурации файла окружения:

```
mv /usr/lib/systemd/system/httpd.service /usr/lib/systemd/system/httpd@.service

vi /usr/lib/systemd/system/httpd@.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

В самом файле окружения (которых будет два) задается опция для запуска веб-сервера с необходимым конфигурационным файлом:
в ``/etc/sysconfig/httpd-first``

```
vi /etc/sysconfig/httpd-first
OPTIONS=-f conf/first.conf
```

а в ``/etc/sysconfig/httpd-second``

```
vi /etc/sysconfig/httpd-second
OPTIONS=-f conf/second.conf
```

Соответственно в директории с конфигами httpd должны лежать два
конфига, в нашем случае это будут ``first.conf`` и ``second.conf``

```
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf
```

Для удачного запуска, в конфигурационных файлах должны быть указаны
уникальные для каждого экземпляра опции Listen и PidFile. Конфиги можно
скопировать и поправить только второй, в нем должны быть след опции:

```
vi /etc/httpd/conf/second.conf 
PidFile /var/run/httpd-second.pid
Listen 8080
```

Этого достаточно для успешного запуска.
Запустим:

```
systemctl start httpd@first
systemctl start httpd@second
```

Проверить можно несколькими способами, например посмотреть какие порты слушаются:

```
ss -tnulp | grep httpd
```

# Скачать демо-версию Atlassian Jira и переписать основной скрипт запуска на unit-файл

Создаем каталог и скачиваем туда бинарник демо-версии Jira

```
mkdir /tmp/jira_installer
cd /tmp/jira_installer
yum -y install wget
wget https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-software-8.0.0-x64.bin
chmod +wx /tmp/jira_installer/atlassian-jira-software-8.0.0-x64.bin
```

Создадим в этом же каталоге файл автоответов, работать Jira будет на порту 8081

```
vi /tmp/jira_installer/response.varfile
#install response file for JIRA
launch.application$Boolean=true
rmiPort$Long=8005
app.jiraHome=/var/atlassian/application-data/jira
app.install.service$Boolean=true
existingInstallationDir=/opt/JIRA Software
sys.confirmedUpdateInstallationString=false
sys.languageId=en
sys.installationDir=/opt/atlassian/jira
executeLauncherAction$Boolean=true
httpPort$Long=8081
portChoice=default
```

Устанавливаем Jira, указав файла автоответа:

```
./atlassian-jira-software-8.0.0-x64.bin -q -varfile response.varfile
```

Создаем юнит службы Jira:

```
vi /usr/lib/systemd/system/jira.service

[Unit]
Description=JIRA Service
After=network.target iptables.service firewalld.service firewalld.service httpd.service

[Service]
Type=forking
User=jira
ExecStart=/opt/atlassian/jira/bin/start-jira.sh
ExecStop=/opt/atlassian/jira/bin/stop-jira.sh

[Install]
WantedBy=multi-user.target
```

Поскольку Jira запустится автоматически после установки, остановим ее через kill перед запуском нашего юнита:

```
kill -15 $(pidof java)
```

Затем запустим сервис уже в systemd:

```
systemctl daemon-reload
systemctl start jira
systemctl enable jira
systemctl status jira
```

Можно проверить, что jira слушает порт 8081:

```
ss -tnulp | grep java
```
