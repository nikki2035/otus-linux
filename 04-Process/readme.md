# работаем с процессами
Задания на выбор
1. написать свою реализацию ps ax используя анализ /proc.\
Результат ДЗ - рабочий скрипт который можно запустить
скрипт psax.sh

```
1876	null	S	784	/usr/bin/pulseaudio--daemonize=no
1884	null	S	325	/usr/bin/gnome-keyring-daemon--daemonize--login
1892	null	S	108	/usr/bin/dbus-daemon--session--address=systemd:--nofork--nopidfile--systemd-activation--syslog-only
1894	tty2	S	0	/usr/libexec/gdm-x-session--run-script/usr/bin/gnome-session
1899	tty2	S	5685	/usr/libexec/Xorgvt2-displayfd3-auth/run/user/1000/gdm/Xauthority-backgroundnone-noreset-keeptty-verbose3
1915	null	S	1	/usr/libexec/gnome-session-binary
```

2. написать свою реализацию lsof\
Результат ДЗ - рабочий скрипт который можно запустить

3. дописать обработчики сигналов в прилагаемом скрипте, оттестировать, приложить сам скрипт, инструкции по использованию.\
Результат ДЗ - рабочий скрипт который можно запустить + инструкция по использованию и лог консоли

4. реализовать 2 конкурирующих процесса по IO. пробовать запустить с разными ionice\
Результат ДЗ - скрипт запускающий 2 процесса с разными ionice, замеряющий время выполнения и лог консоли

5. реализовать 2 конкурирующих процесса по CPU. пробовать запустить с разными nice\
Результат ДЗ - скрипт запускающий 2 процесса с разными nice и замеряющий время выполнения и лог консоли
