#!/usr/bin/env bash

set -o errexit
set -o nounset

readonly dir="$(cd -- "$(dirname "$0")" >/dev/null 2>&1; pwd -P)"

readonly consul_ver='1.11.4'
readonly consul_bin="$dir/consul"

readonly rmq_host_name="$(hostname)"
readonly rmq_ver='3.9.13'
readonly rmq_dir="$dir/rabbitmq_server-$rmq_ver"

readonly rabbitmqctl_cmd="$rmq_dir/sbin/rabbitmqctl"
readonly rabbitmq_plugins_cmd="$rmq_dir/sbin/rabbitmq-plugins"
readonly rabbitmq_server_cmd="$rmq_dir/sbin/rabbitmq-server"

if [[ ! -x $consul_bin ]]
then
    curl -LO "https://releases.hashicorp.com/consul/$consul_ver/consul_${consul_ver}_linux_amd64.zip"
    unzip "consul_${consul_ver}_linux_amd64.zip"
fi

if [[ ! -d $rmq_dir ]]
then
    curl -LO "https://github.com/rabbitmq/rabbitmq-server/releases/download/v$rmq_ver/rabbitmq-server-generic-unix-$rmq_ver.tar.xz"
    tar xf "rabbitmq-server-generic-unix-$rmq_ver.tar.xz"
fi

rm -rf "$rmq_dir/var/log/rabbitmq/"*
rm -rf "$rmq_dir/var/lib/rabbitmq/"*

declare -i IDX=0

for IDX in 0 1 2
do
    rmq_node_name="rabbit$IDX@$rmq_host_name"
    declare -i rmq_node_port="$((5672 + $IDX))"
    rmq_conf="$dir/rabbit$IDX.conf"

    "$rabbitmq_plugins_cmd" -n "$rmq_node_name" enable rabbitmq_peer_discovery_consul

    RABBITMQ_NODENAME="$rmq_node_name" RABBITMQ_NODE_PORT="$rmq_node_port" RABBITMQ_CONFIG_FILE="$rmq_conf" "$rabbitmq_server_cmd" -detached
done

sleep 1

for IDX in 0 1 2
do
    rmq_node_name="rabbit$IDX@$rmq_host_name"
    "$rabbitmqctl_cmd" -n "$rmq_node_name" await_startup
done

for IDX in 1 2
do
    rmq_node_name="rabbit$IDX@$rmq_host_name"
    "$rabbitmqctl_cmd" -n "$rmq_node_name" stop_app
    "$rabbitmqctl_cmd" -n "$rmq_node_name" join_cluster "rabbit0@$rmq_host_name"
    "$rabbitmqctl_cmd" -n "$rmq_node_name" start_app
done
