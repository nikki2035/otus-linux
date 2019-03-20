#!/usr/bin/env bash

echo "PID     TTY     STAT    TIME    COMMAND"    

exec 2>/dev/null
for num_pid in `find /proc -maxdepth 1 -name "[1-9]*" -type d ` 
    do
        pid=$(cat /$num_pid/status | awk '/^Pid/{print $2}')  

        tty=$(readlink $num_pid/fd/0 | cut -d "/" -f3)
        [ -z "$tty" ] && tty="null"

        stat=$(cat /$num_pid/status | awk '/^State/{print $2,$3}' | cut -c1-1)   

        tpm=$(getconf CLK_TCK)
        stat14=$(cut -d " " -f14 $num_pid/stat)
        stat15=$(cut -d " " -f15 $num_pid/stat)
        time=$((($stat14+$stat15)/$tpm))

        sh_name=$(cat /$num_pid/status | awk '/^Name/{print $2}')
        command=$(cat /$num_pid/cmdline | cut -c 1-170)     
        cmdline=$(if grep -q "[a-z,A-Z,0-9]" $num_pid/cmdline; then echo $command; else echo "[$sh_name]"; fi)

        printf "%s\t%s\t%s\t%s\t%s\n" $pid $tty $stat $time $cmdline
    done
}

printf "PID\tTTY\tSTAT\tCOMMAND\n"
