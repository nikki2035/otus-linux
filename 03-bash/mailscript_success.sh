#!/bin/bash
LANG="en_US.UTF8" ; export LANG
#время и дата
now=$(date)
#список переменных для отладки
env=$(env)
#имя сети
network=$(echo $config | awk -F. '{print $1}')
#Адрес LDAP-сервера
ldapserver='<адрес DC>'
#пароль учётной записи для запросов к LDAP
pass='<pass>'
#LDAP-запрос для получения email
mail=$(ldapsearch -h $ldapserver -x -b 'DC=DOMAIN,DC=COM' -D 'cn=ldapsearch,ou=Operators,dc=DOMAIN,dc=COM' -w $pass "(&(objectclass=User)(sAMAccountName=$username))" | grep mail | cut -c 7-)
#текст письма
body="<html><body>Было осуществлено успешное подключение под учетной записью $username c ip $trusted_ip к VPN-сети $network.<br>
Время подключения: $now.<br> 
Если вы не совершали данное подключение, просим вас незамедлительно об этом сообщить в ИТ отдел по любому доступному каналу связи.<br> 
<br>
Контакты ИТ-отдела: email тел: phone доб. 404<br>
<br>
<br>
A successful connection under the account $username to VPN-network $network has been carried out.<br>
Connection time: $now<br>
If you didn't do it, then please contact IT-department, using any available contact.<br>
<br>
Контакты ИТ-отдела: email тел: phone доб. 404<br>
</body></html>"
#расположение файла со списком пар user:ip
white_list=/.../white.list
#шаблон строки
pattern="(^([A-Za-z0-9-]{2,15}):(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$)"
#если файл существует, строка проверяется на соответствие паттерну и паре user:ip
if [ -e $white_list ]; then
    while read line; do
        if [[ $line =~ $pattern ]]; then
            if [[ $line =~ $username:$trusted_ip ]]; then
               exit 0
            fi
        fi
    done < $white_list
fi

/usr/bin/mail -s "$(echo -e "VPN connection established\nContent-Type: text/html; charset=utf-8")" -r "VPN-server email" $mail <<< $body
