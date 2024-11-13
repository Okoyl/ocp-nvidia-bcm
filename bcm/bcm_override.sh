#!/bin/bash



install_aicli() {
  pip install aicli
}

setup_dirs() {
  mkdir -p /var/www/html/workaround
  mkdir -p /var/www/html/workaround/certificates
  mkdir -p /var/www/html/workaround/rhcos
  mkdir -p /tftpboot/images/rhcos/
}


download_rhcos() {
  # check if the files are already downloaded then skip
  if [ -f /tftpboot/images/rhcos/initrd ] && [ -f /tftpboot/images/rhcos/kernel ] && [ -f /var/www/html/workaround/rhcos/rootfs ]; then
    return
  fi

  INITRD_URL=$(grep -oP '^initrd --name initrd \Khttp[^\s]+' $1)
  wget $INITRD_URL -O /tftpboot/images/rhcos/initrd
  wget "http://api.openshift.com/api/assisted-images/boot-artifacts/kernel?arch=x86_64&version=4.17" -O /tftpboot/images/rhcos/kernel
  wget "http://api.openshift.com/api/assisted-images/boot-artifacts/rootfs?arch=x86_64&version=4.17" -O /var/www/html/workaround/rhcos/rootfs
}

setup_pxe() {
  # check if the pxe file is already modified then skip
  if grep -q "rhcos" /tftpboot/pxelinux.cfg/category.default; then
    return
  fi

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
}

if [ -z "$1" ]; then
    echo "Please provide ipxe script"
    exit 1
fi


install_aicli
setup_dirs
download_rhcos $1
setup_pxe
