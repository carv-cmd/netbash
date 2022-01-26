#!/bin/bash

PROGNAME=${0##*/}

sh_c='sh -c'
ECHO=${ECHO:-}
[ "$ECHO" ] && sh_c='echo'

Usage () {
    cat >&2 <<- EOF
usage: $PROGNAME
EOF
}

Error () {
    echo -e "-${PROGNAME%.*} error: $1\n" > /dev/stderr
    exit 1
}

run_openvpn_with_debug () {
    cat <<- EOF
docker run -v $OVPN_VOLUME -p $PORT_MAP/udp --cap-add=NET_ADMIN -e DEBUG=1 $KYLE_VPN
EOF
}

test_installation () {
    # TODO: Download openvpn client on system w/o server?
    # "Test using a client that has openvpn installed correctly"
    $sh_c "openvpn --config $CLIENT_NAME.ovpn"
}

net_checks () {
    # Checks connectivity bypassing name resolvers
    ping_ip_addr '8.8.8.8' || ping_ip_addr '1.1.1.1'
    # Bypass search directives in resolv.conf
    dig google.com
    # Use DNS name resolvers
    nslookup google.com
}

ping_ip_addr () {
    if ! ping -W 30 -c 3 "$1"; then
        return 1
    else
        return 0
    fi
}

main () {
    $sh_c "`run_openvpn_with_debug`"
    test_installation
}

sh_c='echo'
main

