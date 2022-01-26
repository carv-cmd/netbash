#!/bin/bash

PROGNAME=${0##*/}

sh_c='sh -c'
ECHO=${ECHO:-}
[ "$ECHO" ] && sh_c='echo'

COMMAND="$1"
ARGS="$@"


Usage () {
    cat >&2 <<- EOF

arpa_tools:

  hostinfo:
    - who
    - uname
    - whoami
    - hostname
    - neofetch 
  configuration:
    - netplan [try && apply]
    - /etc/hosts
    - /etc/netplan/*.conf
  addressing:
    - lshw -class network
    - arp 
    - ip 
    - ifconfig
  dns_services:
    - dig
    - nslookup
    - resolvectl 
    - host
    - whois
  topography:
    - arping
    - ping
    - route
    - traceroute 
    - netstat
    - nicstat
    - nmap
  live_connections:
    - tcpdump
    - socat
    - nc
    - ssh
    - telnet
    - iperf
    - netperf

misc_helpers:
  syslog:
    - logger -t LABEL MSG
    - journalctl -f -t LABEL
  daters:
    - curl
    - batcat (bat)
    - jq
  words:
    - wamerican[-large]
  isec:
    - openssl [rand -hex 32]
    - mktemp
    - shuf
    - hash

EOF
}

Error () {
    echo -e "-${PROGNAME%.*} error: $1\n" > /dev/stderr
    exit 1
}

run_command () {
    if ! $sh_c $COMMAND; then
        Error "'$COMMAND' failed"
    fi
}

main () {
    echo 'foobar'
}

Usage

