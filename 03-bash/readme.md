# Скрипт оповещения о подключении к VPN предприятия

## Задача

1) при успешном подключении к VPN пользователю отправляется письмо с информацией об адресе, с которого выполнено подключение, времени и к какой именно сети он подключился.
2) при неудачной попытке подключения, вызванной неверным паролем так же отправляется предупреждение.

## Дополнительные требования

1) адрес электронной почты получается и Active Directory (оповещения должны отправляться в том числе на сторонние адреса)
2) для успешных подключений должен быть белый список пар логинов и IP-адресов, при подключении с которых не будут приходить оповещения (домашние белые IP и другие известные и часто используемые для подключений адреса)

## Вызов скриптов

В конфигурации VPN-сетей в OpenVPN указывается, какой скрипт вызывается при событии:

```
script-security 2
client-connect /etc/admin-scripts/mailscript_success.sh
auth-user-pass-verify /etc/admin-scripts/mailscript_fail.sh via-env
```

## Список переменных, которые передаёт OpenVPN скрипту

ifconfig_pool_remote_ip=\
untrusted_ip=\
ifconfig_local=\
proto_1=\
IV_GUI_VER=1\
tun_mtu=\
IV_COMP_STUBv2=\
IV_LZ4v2=\
ifconfig_netmask=\
time_unix=\
redirect_gateway=\
IV_COMP_STUB=\
script_type=\
IV_LZ4=\
verb=\
username=\
local_port_1=\
config=\
ifconfig_pool_netmask=\
dev=\
local_1=\
auth_control_file=\
trusted_port=\
remote_port_1=\
PWD=\
IV_PLAT=\
daemon=\
IV_PROTO=\
ifconfig_broadcast=\
untrusted_port=\
SHLVL=\
script_context=\
IV_LZO=\
daemon_start_time=\
IV_TCPNL=\
trusted_ip=\
daemon_pid=\
IV_NCP=\
time_ascii=\
daemon_log_redirect=\
link_mtu=\
IV_VER=\
_=/usr/bin/env