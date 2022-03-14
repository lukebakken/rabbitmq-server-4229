#!/usr/bin/env bash

set -o errexit
set -o nounset

readonly dir="$(cd -- "$(dirname "$0")" >/dev/null 2>&1; pwd -P)"

readonly consul_ver='1.11.4'
readonly consul_bin="$dir/consul"

readonly rmq_ver='3.9.13'
readonly rmq_dir="$dir/rabbitmq_server-$rmq_ver"
readonly rmq_conf="$dir/rabbitmq.conf"

readonly rabbitmqctl_cmd="$rmq_dir/sbin/rabbitmqctl"
readonly rabbitmq_plugins_cmd="$rmq_dir/sbin/rabbitmq-plugins"
readonly rabbitmq_server_cmd="$rmq_dir/sbin/rabbitmq-server"

declare -i IDX=0

set +o errexit
for IDX in 0 1 2
do
    rmq_host_name="rabbit$IDX-host"
    rmq_node_name="rabbit@$rmq_host_name"
    "$rabbitmqctl_cmd" -n "$rmq_node_name" shutdown --no-wait
done
