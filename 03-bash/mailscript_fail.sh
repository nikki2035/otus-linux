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
body="<html><body>Была осуществлена попытка подключения под учетной записью $username c ip $untrusted_ip к VPN-сети $network.<br>
Время подключения: $now.<br>
Если вы не совершали данное подключение, просим вас незамедлительно об этом сообщить в ИТ отдел по любому доступному каналу связи.<br>
<br>
Контакты ИТ-отдела: email тел: phone доб. 404<br>
<br>
<br>
Failed connection attempt has been made under the account $username from the IP $untrusted_ip to VPN-network $network.<br>
Connection time: $now<br>
If you didn't do it, then please contact IT-department, using any available contact.<br>
<br>
IT-department contacts: email, phone number: phone ext. 404<br>
</body></html>"

logmessage=$(tail -n 10 /var/log/openvpn/openvpn.log | grep "$untrusted_port PLUGIN_CALL: plugin function PLUGIN_AUTH_USER_PASS_VERIFY failed with status 1")
if [ ! -z "$logmessage" ]
then
#/usr/bin/mail -s "VPN соединение не установлено" -r fobos@elvees.com $mail <<< $body
/usr/bin/mail -s "$(echo -e "VPN connection failed\nContent-Type: text/html; charset=utf-8")" -r "VPN-server email" $mail <<< $body
fi
