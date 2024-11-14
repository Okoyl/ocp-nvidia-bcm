#!/bin/bash
set -e


workdir="/tmp/ignition"
manifests="$workdir/manifests"
keys="$workdir/keys"
cmd_keys="/cm/local/apps/cmd/etc/"
ignition_output="transpiled_config.ign"
cluster_name=$1
hostname=$2


create_ignition_override_param_file() {
  echo "Creating ignition override params file"
  rm -rf $workdir || true
  mkdir -p $keys
  cp /etc/hosts $workdir
  cp $cmd_keys/*pem $keys
  cp $cmd_keys/*key $keys
  cp $HOME/.ssh/id_ecdsa.pub $workdir

  cp ignition-override/discovery-butane.yaml $workdir/discovery-butane.yaml
  sed -i "s/SET-HOSTNAME/$hostname/g" $workdir/discovery-butane.yaml
  sed -i "s/SSH-KEY/$(cat $HOME/.ssh/id_ecdsa.pub)/g" $workdir/discovery-butane.yaml

  podman run --interactive --net=host --rm --security-opt label=disable -v $workdir:/pwd --workdir /pwd \
    quay.io/coreos/butane:release -d /pwd --pretty --strict discovery-butane.yaml > $ignition_output

  cat <<EOF > params.json
  {
      "ignition_config_override": $(cat $ignition_output | jq -c | jq -R)
  }
EOF
}

discovery_iso_override() {
  echo "Setting ignition_config_override in infraenv"
  aicli update infraenv $cluster_name"_infra-env" --pf params.json
}

wait_for_host() {
  until [[ "$(aicli -o json info cluster "$cluster_name" | jq -r .hosts[0].status)" == "known" ]]; do
      echo "Waiting for host status to be known..."
      sleep 5  # Wait 5 seconds before checking again
  done

  echo "Host status is known."
}

wait_for_cluster_state() {
  until [[ "$(aicli -o json info cluster "$cluster_name" | jq -r .status)" == "$1" ]]; do
      echo "Waiting for cluster to be $1..."
      sleep 5  # Wait 5 seconds before checking again
  done

  echo "Cluster is $1."
}

start_installation() {
  host_id=$(aicli -o json info cluster $cluster_name  | jq -r .hosts[0].id)

  echo "Setting hostname"
  aicli update host $host_id -P requested_hostname=$hostname

  rm -rf $manifests
  cp ignition-override/machine-config.yaml $workdir/machine-config.yaml
  sed -i "s/SSH-KEY/$(cat $HOME/.ssh/id_ecdsa.pub)/g" $workdir/machine-config.yaml

  mkdir -p $manifests
  podman run --interactive --net=host --rm --security-opt label=disable --volume $workdir:/pwd \
  --workdir /pwd quay.io/coreos/butane:release -d /pwd machine-config.yaml > $manifests/99-master-cmd.yaml

  aicli create  manifest --dir $manifests $cluster_name
  aicli start cluster $cluster_name
}
