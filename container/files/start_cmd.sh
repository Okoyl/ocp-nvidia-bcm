#!/bin/bash

CMD_HOST="10.141.254.255"
CMD_ETC_DIR="/cm/local/apps/cmd/etc"
CERT_FILE="$CMD_ETC_DIR/cert.pem"
KEY_FILE="$CMD_ETC_DIR/cert.key"

MAC_ADDRESSES_ARRAY=($(ip link show | grep -o -E '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}'))

if [[ ! -f "$KEY_FILE" || ! -f "$CERT_FILE" ]]; then
    # Loop through all MAC addresses
    for MAC in "${MAC_ADDRESSES_ARRAY[@]}"; do
        # Check if certificate exists
        if wget -q --spider http://$CMD_HOST/workaround/certificates/$MAC/cert.pem; then
            wget http://$CMD_HOST/workaround/certificates/$MAC/cert.pem -O $CERT_FILE
            wget http://$CMD_HOST/workaround/certificates/$MAC/cert.key -O $KEY_FILE
            break
        fi
fi

# Check and create Diffie-Hellman parameters
if [[ ! -f "$DH_FILE" ]]; then
    echo "Generating DH parameters..."
    openssl dhparam -out "$DH_FILE" 1024
fi

export $(grep -v '^#' /cm/local/apps/cmd/etc/cmd.env | xargs)

/cm/local/apps/cmd/sbin/safe_cmd /cm/local/apps/cmd/sbin/cmd "-s -n -P /var/run/cmd.pid" "${CMD_DIR}" "/var/run/cmd.pid"
/cm/local/apps/cmd/sbin/wait_cmd "${MAINPID}x" /var/run/cmd.pid
