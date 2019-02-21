Реализовать это все либо в Vagrant, либо развернуть у себя через NGINX и дать ссылку на репозиторий.

# Создать свой RPM пакет

Нам понадобятся следующие установленные пакеты:
```
yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils zlib-devel pcre-devel openssl-devel gcc lynx
```

Для примера возьмем пакет NGINX и соберем его с поддержкой openssl\
Загрузим SRPM пакет NGINX для дальнейшей работы над ним:
```
wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm
```
При установке такого пакета в домашней директории создается древо каталогов для сборки:
```
rpm -i nginx-1.14.1-1.el7_4.ngx.src.rpm
```
Также нужно скачать и разархивировать последние исходники для openssl - он потребуется при сборке
```
wget https://www.openssl.org/source/latest.tar.gz
tar -xvf latest.tar.gz
```
Заранее поставим все зависимости чтобы в процессе сборки не было ошибок
```
yum-builddep rpmbuild/SPECS/nginx.spec
```
Ну и собственно поправить сам spec файл чтобы NGINX собирался с необходимыми нам опциями:
```
sed -i 's|--with-debug|--with-openssl=/root/openssl-1.1.1a|' /root/rpmbuild/SPECS/nginx.spec
```
Теперь можно приступитьþ к сборке RPM пакета:
```
rpmbuild -bb rpmbuild/SPECS/nginx.spec
```
Убедимся, что пакеты создались:
```
ll rpmbuild/RPMS/x86_64/
-rw-r--r--. 1 root root 1999864 Nov 29 06:15 nginx-1.14.1-1.el7_4.ngx.x86_64.rpm
-rw-r--r--. 1 root root 2488840 Nov 29 06:15 nginx-debuginfo-1.14.1-1.el7_4.ngx.x86_64.rpm
```
Теперь можно установить наш пакет и убедиться, что nginx работает
```
yum localinstall -y rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm
systemctl start nginx
systemctl status nginx
```
# Создать свой репозиторий и разместить там ранее собранный RPM

Далее мы будем использовать его для доступа к своему репозиторию
Теперь приступим к созданию своего репозитория. Директория для статики у NGINX по умолчанию /usr/share/nginx/html. Создадим там каталог repo:
```
mkdir /usr/share/nginx/html/repo
```
Копируем туда наш собранный RPM и, например, RPM для установки репозитория Percona-Server:
```
cp rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm /usr/share/nginx/html/repo/
wget http://www.percona.com/downloads/percona-release/redhat/0.1-6/percona-release-0.1-6.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-0.1-6.noarch.rpm
```
Инициализируем репозиторий командой:
```
createrepo /usr/share/nginx/html/repo/
```

Для прозрачности настроим в NGINX доступ к листингу каталога:
```
sed -i '10a\ autoindex on;\' /etc/nginx/conf.d/default.conf
```
В location / в файле /etc/nginx/conf.d/default.conf добавим директиву autoindex on. В результате location будет выглядеть так:
```
location / {
root /usr/share/nginx/html;
index index.html index.htm;
autoindex on;
}
```
Проверяем синтаксис и перезапускаем NGINX:
```
nginx -t
nginx -s reload
```
Теперь можно посмотреть в браузере или curl:
```
lynx http://localhost/repo/
curl -a http://localhost/repo/
```
Добавим репозиторий в /etc/yum.repos.d:
```
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
```
Убедимся что репозиторий подкличился и посмотрим что в нем есть:
```
yum repolist enabled | grep otus
yum list | grep otus
```
Так как NGINX у нас уже стоит установим репозиторий percona-release:
```
yum install -y percona-release
```
Все прошло успешно. В случае если вам потребуется обновить репозиторий (а это делается при каждом добавлении файлов), снова то выполните команду 
```
createrepo /usr/share/nginx/html/repo/
```
