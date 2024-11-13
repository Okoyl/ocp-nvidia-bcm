#!/bin/bash

export $(grep -v '^#' /cm/local/apps/cmd/etc/cmd.env | xargs)

mount.nfs master:/cm/shared /cm/shared/

/cm/local/apps/cmd/sbin/safe_cmd /cm/local/apps/cmd/sbin/cmd "-s -n -P /var/run/cmd.pid" "${CMD_DIR}" "/var/run/cmd.pid"
# /cm/local/apps/cmd/sbin/wait_cmd "${MAINPID}x" /var/run/cmd.pid

# /cm/local/apps/cmd/sbincmd &

# /cm/local/apps/slurm/bin/slurmd &

