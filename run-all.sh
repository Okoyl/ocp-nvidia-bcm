#!/bin/bash
set -e
source ignition-override/ignition.sh

cluster_name=$1

create_cluster() {
  aicli delete cluster $cluster_name -y
  aicli create cluster $cluster_name -P sno=true -P pull_secret=openshift_pull.json
}

create_cluster
create_ignition_override_param_file
discovery_iso_override

source bcm/bcm_override.sh

wait_for_host
wait_for_cluster_state ready
start_installation
wait_for_cluster_state installed

echo "Done"
