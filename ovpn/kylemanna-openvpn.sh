#!/bin/bash

# use systemd-service to auto start/restart

sh_c='sh -c'
ECHO=${ECHO:-}
[ "$ECHO" ] && sh_c='echo'

READZERO="$(readlink -f $0)"
WHEREAMI=${READZERO%/*}
PROGNAME=${READZERO##*/}

KYLE_VPN='kylemanna/openvpn'
UDP_SERVER_HOST='udp://VPN.SERVERNAME.COM'
PORT_MAP='1194:1194'
CLIENT_NAME='CLIENTNAME'

OVPN_LABEL="proxy-000"
OVPN_VOLUME="$OVPN_LABEL:/etc/openvpn"
DEBUG=


Usage () {
    cat >&2 <<- EOF
usage: $PROGNAME [OPTIONS]

Options:
 -d, --debug            See $WHEREAMI/debug-openvpn.sh
 -e, --echos            Echo commands that would run
 -h, --help             Print this help message and exit
 -c, --client-name      TODO: whatis
 -u, --udp-host         TODO: whatis
 -v, --volume-label     ovpn-data-[volume-label:-proxy] 
 -p, --publish          Ports to expose. See docker -p

EOF
exit 1
}

Error () {
    echo -e "-${PROGNAME%.*} error: $1\n" > /dev/stderr
    exit 1
}

ovpn_volume_name () {
    OVPN_VOLUME_LABEL="ovpn-data-$OVPN_LABEL"
    OVPN_VOLUME="$OVPN_VOLUME_LABEL:/etc/openvpn"
}

init_docker_ovpn () {
    # Run container to hold config files and certs.
    # Prompts for passphrase.
    cat <<- EOF
docker volume create --name $OVPN_LABEL 
docker run -v $OVPN_VOLUME --rm $KYLE_VPN ovpn_genconfig -u $UDP_SERVER_HOST
docker run -v $OVPN_VOLUME --rm -it $KYLE_VPN ovpn_initpki
EOF
}

start_open_vpn_server_proc () {
    cat <<- EOF
docker run -v $OVPN_VOLUME -d -p $PORT_MAP/udp --cap-add=NET_ADMIN $KYLE_VPN
EOF
}

generate_client_cert () {
    cat <<- EOF
docker run -v $OVPN_VOLUME --rm -it $KYLE_VPN easyrsa build-client-full $CLIENT_NAME nopass
EOF
}

client_conf_w_embedded_certs () {
    cat <<- EOF
docker run -v $OVPN_VOLUME --rm $KYLE_VPN ovpn_client $CLIENT_NAME > $CLIENT_NAME.ovpn
EOF
}

###
parse_args () {
    while [ -n "$1" ]; do
        _args="$1"; shift
        case "$_args" in 
            -v | --volume-label ) OVPN_LABEL="$1";;
            -c | --client-name ) CLIENT_NAME="$1";;
            -u | --udp-host ) UDP_SERVER_HOST="$1";;
            -p | --publish ) PORT_MAP="$1";;
            -d | --debug ) DEBUG=1; continue;;
            -e | --echos ) sh_c='echo'; continue;;
            -h | --help ) Usage;;
            -* | --* ) Error "invalid arg: $_args";;
        esac
        shift
    done
}

main () {
    ovpn_volume_name
    OVPN_BUILDER=( \
        init_docker_ovpn 
        start_open_vpn_server_proc \
        generate_client_cert \
        client_conf_w_embedded_certs 
    )
    for _execute in ${OVPN_BUILDER[@]}; do 
        $sh_c "`$_execute`" || Error "fatal: $_execute"
    done
}

[ -n "$1" ] && parse_args "$@"
if [ "$DEBUG" ]; then
    export ECHO OVPN_VOLUME PORT_MAP KYLE_VPN CLIENT_NAME
    $WHEREAMI/debug-openvpn.sh
else
    main
fi

