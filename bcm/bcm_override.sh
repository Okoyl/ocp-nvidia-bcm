#!/bin/bash

mkdir /var/www/html/workaround
mkdir /var/www/html/workaround/certificates
mkdir /var/www/html/workaround/rhcos

mkdir /tftpboot/images/rhcos/
wget "http://api.openshift.com/api/assisted-images/boot-artifacts/kernel?arch=x86_64&version=4.17" -O /tftpboot/images/rhcos/kernel


wget "http://api.openshift.com/api/assisted-images/boot-artifacts/rootfs?arch=x86_64&version=4.17" -O /var/www/html/workaround/rhcos/rootfs


# PXE SETUP for RHCOS

DEFAULT_PXE_FILE="/tftpboot/pxelinux.cfg/category.default"

cp $DEFAULT_PXE_FILE $DEFAULT_PXE_FILE.bak

DEFAULT_PXE=$(cat "$DEFAULT_PXE_FILE")
DEFAULT_PXE=$(echo "$DEFAULT_PXE" | sed '/MENU DEFAULT/d')

cat <<EOF > $DEFAULT_PXE_FILE
LABEL rhcos
  KERNEL images/rhcos/kernel
  IPAPPEND 3
  APPEND initrd=images/rhcos/initrd  rd.driver.blacklist=nouveau coreos.live.rootfs_url=http://10.141.255.254/workaround/rhcos/rootfs random.trust_cpu=on rd.luks.options=discard ignition.firstboot ignition.platform.id=metal console=tty0 console=ttyS0
  MENU LABEL ^RHCOS      - Red hat core os
  MENU DEFAULT
EOF

echo "$DEFAULT_PXE" >> $DEFAULT_PXE_FILE

